# Recipes for PCA ------------------------------------------------------------

#' Automatic Recipes for PCA
#'
#' @description use `recipes` package to `step_nzv`,`step_naomit`, `step_normalize`, `step_pca`, and `prep`
#' @param df data frame
#' @param fct_vars (character) Factor variables to choose as ID (if `NULL`, choose all factor variables in data frame)
#' @param num_vars (character) Numeric variables to choose as feature (if `NULL`, choose all numeric variables in data frame)
#'
#' @return recipe object
#' @importFrom magrittr %>%
#' @importFrom purrr keep
#' @importFrom dplyr all_of select
#' @importFrom recipes recipe update_role step_nzv step_naomit step_normalize step_pca prep
#' @export
#'
#' @examples prep_pca(iris)
prep_pca <- function(df, fct_vars = NULL, num_vars = NULL) { # If NULL : Automatic select

  # require(recipes)
  # require(dplyr)

  if(is.null(fct_vars)){
    fct_vars <- df %>% purrr::keep(is.factor) %>% names()
  }

  if(is.null(num_vars)){
    num_vars <- df %>% purrr::keep(is.numeric) %>% names()
  }

  df <- df %>% dplyr::select(dplyr::all_of(fct_vars), dplyr::all_of(num_vars))

  recipes::recipe(~., data = df) %>%
    recipes::update_role(dplyr::all_of(fct_vars), new_role = "id") %>%
    recipes::step_nzv(recipes::all_predictors()) %>%
    recipes::step_naomit(recipes::all_predictors()) %>%
    recipes::step_normalize(recipes::all_predictors()) %>%
    recipes::step_pca(recipes::all_predictors(), id = "pca") %>%
    recipes::prep()


}

# Scree Plot --------------------------------------------------------------

#' PCA Screeplot
#'
#' @param pca_recipe Object class recipe that already `step_pca`
#' @param terms (character) To specify the y-axis, must be one of "var" for variance, "percent_var" for percent variance, and "cum_var" for cumulative percent variance
#' @param title (character) Title of the plot
#' @param y Y-axis label: `NA` for default label, character to specify your own label, or `NULL` to remove label
#' @param ... passed to `ggplot2::labs`
#'
#' @return plot
#' @importFrom magrittr %>%
#' @importFrom dplyr filter
#' @importFrom ggplot2 ggplot aes geom_col labs scale_fill_viridis_c
#' @importFrom yardstick tidy
#' @export
#'
#' @examples
#' library(magrittr)
#' library(lbr)
#' iris %>%
#'   prep_pca() %>%
#'   pca_scree_plot()
pca_scree_plot <- function(pca_recipe, # after prep()
                           terms = "percent_var",
                           title = "Scree Plot",
                           y = NA, # NA = default Y-axis, NULL = remove labs
                           ...) { # ... passed to labs()

  # require(dplyr)
  # require(ggplot2)
  # require(yardstick)

  t <- switch (terms,
               "var" = "variance",
               "percent_var" = "percent variance",
               "cum_var" = "cumulative percent variance",
               stop("`terms` must be 'var', 'percent_var', 'cum_var'", call. = F)
  )

  if(!is.null(y)){
    if( is.na(y) ){
      y <- switch (terms,
                   "var" = "variance",
                   "percent_var" = "% of total variance",
                   "cum_var" = "cumulative variance (%)"
      )
    }}


  var_df <- pca_recipe %>%
    yardstick::tidy(id = "pca", type = "variance") %>%
    dplyr::filter(terms == !!t )

  var_df %>%
    ggplot2::ggplot(ggplot2::aes(component, value)) +
    ggplot2::geom_col(ggplot2::aes(fill = component), show.legend = F) +
    ggplot2::labs(title = title, y = y, ...) +
    ggplot2::scale_fill_viridis_c()

}

# Loading Score Plot ------------------------------------------------------

#' Plot Loading Score from PCA
#'
#' @param pca_recipe Object class recipe that already `step_pca`
#' @param component Integer vector indicate which PCs to show, the default "all" shows every components.
#' @param fill (character) Fill of positive & negative values
#' @param nrow (numeric) Number of rows in facet
#' @param ncol (numeric) Number of columns in facet
#' @param ... passed to `geom_col`
#'
#' @return plot
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate
#' @importFrom ggplot2 ggplot aes geom_col facet_wrap scale_fill_manual labs
#' @importFrom forcats as_factor fct_inorder
#' @importFrom tidytext reorder_within scale_y_reordered
#' @importFrom yardstick tidy
#' @export
#'
#' @examples
#' library(magrittr)
#' library(lbr)
#' iris %>%
#'   prep_pca() %>%
#'   pca_load_plot()
pca_load_plot <- function(pca_recipe,
                          component = "all",
                          fill = c("#b6dfe2", "#0A537D"),
                          nrow = NULL, ncol = NULL,
                          ...) { # To geom_col

  # require(dplyr)
  # require(stringr)
  # require(forcats)
  # require(ggplot2)
  # require(rlang)
  # require(yardstick)

  load_df <- pca_recipe %>%
    yardstick::tidy(id = "pca")

  num_comp <-  if(component == "all"){
    load_df %>%
      dplyr::pull(component) %>%
      unique() %>%
      stringr::str_extract("[:digit:]+")
  }else if(is.numeric(component)){
    component
  }else{ stop("`component must be 'all' or integer vector", call. = F) }

  load_df_mod <- load_df %>%
    # Filter Components
    dplyr::filter(component %in% c(paste0("PC", num_comp ))) %>%
    dplyr::mutate(component = forcats::as_factor(component)) %>%
    dplyr::mutate(component = forcats::fct_inorder(component)) %>%
    dplyr::mutate(terms = tidytext::reorder_within(terms,
                                                   abs(value),
                                                   component))
  load_df_mod %>%
    ggplot2::ggplot(ggplot2::aes(abs(value), terms, fill = value > 0)) +
    ggplot2::geom_col(...) +
    ggplot2::facet_wrap(~component, scales = "free_y", nrow = nrow, ncol = ncol) +
    tidytext::scale_y_reordered() +
    ggplot2::scale_fill_manual(values = fill) +
    ggplot2::labs(
      x = "Absolute value of contribution",
      y = NULL, fill = "Positive?"
    )
}

# Bi-plot (Main function) ------------------------------------------------------------


#' PCA Bi-plot
#' @description Plot PCA bi-plot from `recipe` object that has `step_pca`
#'
#' @param pca_recipe Object class recipe that already `step_pca`
#' @param mapping `ggplot2` aesthetic mapping (passed to `geom_point`)
#' @param x unquoted name to specify which principle component to plot in x-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param y unquoted name to specify which principle component to plot in y-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param alpha point transparency (passed to `geom_point`)
#' @param size size of point (passed to `geom_point`)
#' @param geom_type_scatter (unquoted name) Type of scatter plot: `geom_point` or `geom_text`
#' @param x_origin (numeric) x-origin of the arrow (passed to `lbr::geom_arrow_pca`)
#' @param y_origin (numeric) y-origin of the arrow (passed to `lbr::geom_arrow_pca`)
#' @param arrow_scale (numeric) scale factor of the arrow (passed to `lbr::geom_arrow_pca`)
#' @param color_arrow (character) color of the arrow (passed to `lbr::geom_arrow_pca`)
#' @param geom_type unquoted name of geom to use, must be one of `geom_label`, `geom_label_repel`, `geom_text`, or `geom_text_repel`
#' @param hjust (numeric) passed to `geom_text` or `geom_label`
#' @param vjust (numeric) passed to `geom_text` or `geom_label`
#' @param size_txt (numeric) size of `geom_text` or `geom_label`
#' @param color (character) color of `geom_text` or `geom_label`
#' @param check_overlap passed to `geom_text`
#' @param label.padding passed to `geom_label`
#' @param label.r passed to `geom_label`
#' @param label.size passed to `geom_label`
#' @param segment.color color of the segment, `NA` for no line segment (passed to `geom_label_repel` or `geom_text_repel`)
#' @param min.segment.length minimum length that will draw line segment (passed to `geom_label_repel` or `geom_text_repel`)
#' @param force pushing force for overlapping label (passed to `geom_label_repel` or `geom_text_repel`)
#' @param force_pull pulling force to data points (passed to `geom_label_repel` or `geom_text_repel`)
#' @param max.overlaps maximum label overlapping (passed to `geom_label_repel` or `geom_text_repel`)
#' @param size_ggrepel size of the label (passed to `geom_label_repel` or `geom_text_repel`)
#' @param ... passed to `geom_point`
#'
#' @return plot
#'
#' @importFrom magrittr %>%
#' @importFrom rlang enexpr
#' @importFrom ggplot2 unit
#' @export
#'
#' @examples
pca_biplot <- function(pca_recipe,
                       mapping = NULL,            # aesthetic of geom_point()
                       x = PC1, y = PC2,   # X and Y axis

                       alpha = 0.8, size = 2,      # Point
                       geom_type_scatter = geom_point, ## Type of scatter plot

                       x_origin = 0, y_origin = 0, # Arrow: origin & scale length
                       arrow_scale = 1,
                       color_arrow = "black",

                       geom_type = geom_label,     ## Label : geom_label or geom_text
                       hjust = 0, vjust = 1, size_txt = 3,
                       color = '#0A537D',

                       check_overlap = FALSE, # if Geom_text

                       label.padding = ggplot2::unit(0.25, "lines"), # if Geom_label
                       label.r = ggplot2::unit(0.15, "lines"),
                       label.size = 0.25,

                       # to geom_label_repel or geom_text_repel

                       segment.color = "black", # NA = no line segment
                       min.segment.length = 0.5, # min length to point that draw segment
                       force = 1, # push force for overlapping label
                       force_pull = 1,  # pull force to data point
                       max.overlaps = 10, # maximum label overlap
                       size_ggrepel = 2, # Size of label
                       ... # to geom_point()
) {

  geom_type <- rlang::enexpr(geom_type)
  geom_type_scatter <- rlang::enexpr(geom_type_scatter)

  pca_recipe %>%
    pca_scatter_plot(mapping = mapping, x = {{x}}, y = {{y}},
                     geom_type = !!geom_type_scatter,
                     alpha = alpha, size = size, ...) +
    geom_arrow_pca(pca_recipe,
                   x = {{x}}*arrow_scale,
                   y = {{y}}*arrow_scale,
                   x_origin = x_origin, y_origin = y_origin,
                   color = color_arrow) +
    geom_label_pca(pca_recipe,
                   x = {{x}}*arrow_scale + x_origin,
                   y = {{y}}*arrow_scale + y_origin,
                   geom_type = !!geom_type,
                   hjust = hjust, vjust = vjust, size = size_txt,
                   color = color,
                   check_overlap = check_overlap, # if Geom_text

                   label.padding = label.padding, # if Geom_label
                   label.r = label.r,
                   label.size = label.size,

                   segment.color = segment.color, # if geom_label_repel or geom_text_repel
                   min.segment.length = min.segment.length,
                   force = force,
                   force_pull = force_pull,
                   max.overlaps = max.overlaps,
                   size_ggrepel = size_ggrepel
    )
}




# Scatter plot - plot scatter point individually ------------------------------------------------------------


#' PCA Scatter Plot
#'
#' @param pca_recipe object class recipe that already `step_pca`
#' @param mapping aesthetic i.e. `ggplot2::aes()` mapping
#' @param x unquoted name to specify which principle component to plot in x-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param y unquoted name to specify which principle component to plot in y-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param geom_type unquoted name to specify type of geom to plot: `geom_point` or `geom_text`
#' @param alpha passed to `geom_point`
#' @param size passed to `geom_point`
#' @param ... passed to `geom_point`
#'
#' @return plot
#'
#' @importFrom magrittr %>%
#' @importFrom rlang ensym as_string
#' @importFrom dplyr filter pull
#' @importFrom glue glue
#' @importFrom stringr str_extract
#' @importFrom ggplot2 ggplot aes geom_point labs
#' @importFrom yardstick tidy
#' @importFrom recipes juice
#' @export
#'
#' @examples
#' library(magrittr)
#' library(lbr)
#' iris %>%
#'   prep_pca() %>%
#'   pca_scatter_plot(ggplot2::aes(color = Species))
pca_scatter_plot <- function(pca_recipe,
                             mapping = NULL,
                             x = PC1, y = PC2,
                             geom_type = geom_point,
                             alpha = 0.8, size = 2, ...) {

  # require(recipes)
  # require(ggplot2)
  # require(rlang)
  scatter <- switch (rlang::as_string(rlang::enexpr(geom_type)),
                     "geom_point" = {
                       ggplot2::geom_point(mapping, alpha = alpha, size = size, ...)
                     },
                     "geom_text" = {
                       ggplot2::geom_text(mapping, alpha = alpha, size = size + 2, ...)
                     },
                     stop("`geom_type` must be geom_point or geom_text", call. = F)
  )

  ### Extract PC from x and y
  pc_x <- rlang::ensym(x) %>% rlang::as_string()
  pc_x_num <- pc_x %>% stringr::str_extract("[:digit:]+") %>% as.numeric()

  pc_y <- rlang::ensym(y) %>% rlang::as_string()
  pc_y_num <- pc_y %>% stringr::str_extract("[:digit:]+") %>% as.numeric()

  pca_percent_var <- pca_recipe %>%
    yardstick::tidy(id = "pca", type = "variance") %>%
    dplyr::filter(terms == "percent variance") %>%
    dplyr::pull(value) %>%
    round(1)

  pca_coord <- recipes::juice(pca_recipe)

  pca_coord %>%
    ggplot2::ggplot(ggplot2::aes(x = {{x}}, y = {{y}})) +
    scatter +
    ggplot2::labs(x = glue::glue("{pc_x} ({pca_percent_var[pc_x_num]}%)"),
                  y = glue::glue("{pc_y} ({pca_percent_var[pc_y_num]}%)"))

}



# Label layer - to add to scatter plot ------------------------------------


#' Vector's Label for PCA bi-plot
#'
#' @param pca_recipe Object class recipe that already `step_pca`
#' @param x unquoted name to specify which principle component to plot in x-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param y unquoted name to specify which principle component to plot in y-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param geom_type unquoted name of geom to use, must be one of `geom_label`, `geom_label_repel`, `geom_text`, or `geom_text_repel`
#' @param hjust (numeric) passed to `geom_text` or `geom_label`
#' @param vjust (numeric) passed to `geom_text` or `geom_label`
#' @param size (numeric) passed to `geom_text` or `geom_label`
#' @param color passed to `geom_text` or `geom_label`
#' @param check_overlap passed to `geom_text`
#' @param label.padding passed to `geom_label`
#' @param label.r passed to `geom_label`
#' @param label.size passed to `geom_label`
#' @param segment.color passed to `geom_label_repel` or `geom_text_repel`
#' @param min.segment.length passed to `geom_label_repel` or `geom_text_repel`
#' @param force passed to `geom_label_repel` or `geom_text_repel`
#' @param force_pull passed to `geom_label_repel` or `geom_text_repel`
#' @param max.overlaps passed to `geom_label_repel` or `geom_text_repel`
#' @param size_ggrepel passed to `geom_label_repel` or `geom_text_repel`
#' @param ... passed to geom that specified by `geom_type` argument
#'
#' @return plot label
#'
#' @importFrom magrittr %>%
#' @importFrom rlang as_string enexpr
#' @importFrom tidyr pivot_wider
#' @importFrom ggplot2 unit  aes geom_label geom_text
#' @importFrom ggrepel geom_label_repel geom_text_repel
#' @importFrom yardstick tidy
#' @export
#'
#' @examples
#' library(magrittr)
#' library(lbr)
#' prep_pca(iris) %>%
#'   pca_scatter_plot(ggplot2::aes(color = Species)) +
#'   geom_label_pca(prep_pca(iris))
geom_label_pca <- function(pca_recipe,
                           x = PC1, y = PC2,  # both geom_text or geom_label
                           geom_type = geom_label,
                           hjust = 0, vjust = 1, size = 3,
                           color = '#0A537D',

                           check_overlap = FALSE, # to Geom_text

                           label.padding = ggplot2::unit(0.25, "lines"), # to Geom_label
                           label.r = ggplot2::unit(0.15, "lines"),
                           label.size = 0.25,

                           segment.color = "black", # to geom_label_repel or geom_text_repel
                           min.segment.length = 0.5,
                           force = 1,
                           force_pull = 1,
                           max.overlaps = 10,
                           size_ggrepel = 2,

                           ...) {

  # require(ggplot2)
  # require(yardstick)
  # require(rlang)

  pca_load_wide <- pca_recipe %>%
    yardstick::tidy(id = "pca") %>%
    tidyr::pivot_wider(names_from = component, id_cols = terms)

  switch (rlang::as_string(rlang::enexpr(geom_type)),
          "geom_label" = {

            ggplot2::geom_label(data = pca_load_wide,
                                ggplot2::aes(x = {{x}}, y = {{y}}, label = terms),
                                hjust = hjust,
                                vjust = vjust,
                                size = size,
                                color = color,
                                label.padding = label.padding,
                                label.r = label.r,
                                label.size = label.size, ...)

          },
          "geom_label_repel" = {

            ggrepel::geom_label_repel(mapping = ggplot2::aes(x = {{x}}, y = {{y}}, label = terms),
                                      data = pca_load_wide,

                                      segment.color = segment.color,
                                      min.segment.length = min.segment.length,
                                      force = force,
                                      force_pull = force_pull,
                                      max.overlaps = max.overlaps,
                                      size = size_ggrepel,
                                      ...
            )
          },
          "geom_text" = {

            ggplot2::geom_text(data = pca_load_wide,
                               ggplot2::aes(x = {{x}}, y = {{y}}, label = terms),
                               hjust = hjust,
                               vjust = vjust,
                               size = size,
                               color = color,
                               check_overlap = check_overlap, ...)
          },
          "geom_text_repel" = {

            ggrepel::geom_text_repel(mapping = ggplot2::aes(x = {{x}}, y = {{y}}, label = terms),
                                     data = pca_load_wide,

                                     segment.color = segment.color,
                                     min.segment.length = min.segment.length,
                                     force = force,
                                     force_pull = force_pull,
                                     max.overlaps = max.overlaps,
                                     size = size_ggrepel,
                                     ...
            )

          },
          stop("`geom_type` must be geom_text, geom_text_repel, geom_label or geom_label_repel", call. = F)
  )
}


# Arrow Plot - Add arrow layer to scatter plot --------------------------------------------------------------


#' Arrow for PCA bi-plot
#'
#' @param pca_recipe Object class recipe that already `step_pca`
#' @param x unquoted name to specify which principle component to plot in x-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param y unquoted name to specify which principle component to plot in y-axis (must be one of PC1, PC2, PC3, ... ,etc.)
#' @param x_origin (numeric) x-origin of the arrow
#' @param y_origin (numeric) y-origin of the arrow
#' @param length length of the arrow defined by function `ggplot2::unit` (passed to `ggplot2::arrow`)
#' @param type type of the arrow head (passed to `ggplot2::arrow`)
#' @param color color of the arrow segment (passed to `ggplot2::geom_segment`)
#' @param ... passed to `geom_segment`
#'
#' @return plot arrow
#'
#' @importFrom tidyr pivot_wider
#' @importFrom yardstick tidy
#' @importFrom ggplot2 unit arrow aes geom_segment
#' @export
#'
#' @examples
#' library(magrittr)
#' library(lbr)
#' prep_pca(iris) %>%
#'   pca_scatter_plot(ggplot2::aes(color = Species)) +
#'   geom_arrow_pca(prep_pca(iris))
geom_arrow_pca <- function(pca_recipe,
                           x = PC1,
                           y = PC2,
                           x_origin = 0, y_origin = 0, # Origin of arrow
                           length = ggplot2::unit(.05, "inches"), # Arrow spec
                           type = "closed",
                           color = "black",
                           ... ) {

  # require(yardstick)
  # require(ggplot2)

  arrow_style <- ggplot2::arrow(length = length,
                                type = type)

  pca_load_wide <- pca_recipe %>%
    yardstick::tidy(id = "pca") %>%
    tidyr::pivot_wider(names_from = component, id_cols = terms)


  seg <- ggplot2::geom_segment(data = pca_load_wide,
                               ggplot2::aes(xend = {{x}} + x_origin,
                                            yend = {{y}} + y_origin),
                               x = x_origin ,
                               y = y_origin ,
                               arrow = arrow_style,
                               color = color,
                               ...)


  seg
}


