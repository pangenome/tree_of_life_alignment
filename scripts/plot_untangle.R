args <- commandArgs()
path_untangle_tsv <- args[6]
x_min <- as.numeric(args[7])
x_max <- as.numeric(args[8])
width <- as.numeric(args[9])
title <- args[10]
nth_best <- as.numeric(args[11])
estimated_identity_threshold <- as.numeric(args[12])
#path_annotation <- args[xx]
path_output <- args[13]

library(ggplot2)
library(ggforce)
library(tidyverse)

options(scipen = 999)

panel_spacing <- 0

x <- read.delim(path_untangle_tsv) %>%
  rename(query.name = X.query.name) %>%
  filter(nth.best <= nth_best)
#x <- x[x$self.coverage <= 1,]

# From https://doi.org/10.1093/bioinformatics/btac244
x$estimated_identity <- exp((1.0 + log(2.0 * x$score/(1.0+x$score)))-1.0)

x <- x[x$estimated_identity >= estimated_identity_threshold,]

#colors <- c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF4")
#if (length(unique(x$target)) > 5) {
#  # Mobin's annotations
#  colors <- c(colors, "#000000", "#000000", "#000000", "#000000")
#}

# To group by query
x$query.hacked <- paste(x$query.name, x$nth.best, sep = "-")

x <- x %>%
  arrange(query.hacked)

if (x_max <= 0) {
  x_max <- max(x$ref.end)
}

p <- ggplot(
  x,
  aes(
    x = ref.start + (ref.end - ref.start) / 2,
    y = ordered(query.hacked, levels = rev(unique(query.hacked))),
    width = ref.end - ref.start,
    fill = inv,
    alpha = estimated_identity
  )
) +
  geom_tile() +
  ggtitle(title) +
  #facet_grid(~query.name, scales = "free_y", space = "free", labeller = labeller(variable = labels)) +
  facet_wrap(~query.name, ncol=1, scales = "free_y") +
  theme_bw() +
  theme(
    plot.title = element_text(hjust = 0.5),
    
    text = element_text(size = 16),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 16),
    legend.position = "right",
    
    panel.spacing = unit(panel_spacing, "lines"),
    #panel.border = element_rect(color = "grey", fill = NA, size = 1), #element_blank(),
    
    strip.text.x = element_blank(),
    strip.text.y = element_blank(),
    axis.title.y = element_blank(),
    
    plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm"),
  ) +
  scale_x_continuous(limits = c(x_min, x_max), expand = c(0, 0)) +
  #scale_fill_manual(values = colors) +
  labs(x = "Position", fill="Strand", alpha="Estimated identity") 
p
#+ scale_alpha_discrete(range = c(0.3, 1))# + scale_x_reverse()
ggsave(plot = p, path_output, width = width, height = length(unique(x$query.name))*0.75, units = "cm", dpi = 300, bg = "transparent", limitsize = FALSE)

if (false){
  library(png)
  library(grid)
  img <- readPNG(path_annotation)
  
  ggplotted_img <- ggplot() +
    annotation_custom(
      rasterGrob(img, width = 1, height = 1),
      xmin = - Inf, xmax = Inf,
      ymin = - Inf, ymax = Inf
    ) + theme(
      plot.margin = unit(c(0,1,0.5,2.54), "cm")
    )
  
  library(ggpubr)
  p_with_annotation <- ggpubr::ggarrange(
    ggplotted_img, p,
    labels=c('', ''),
    heights = c(height_bar*10, height_bar*length(unique(xx$query))*nth.best),
    legend = "right", # legend position,
    common.legend = T,
    nrow = 2
  )
  
  ggsave(
    plot = p_with_annotation,
    path_output,
    width = width, height = (12+length(unique(xx$query))*nth.best) * height_bar,
    units = "cm",
    dpi = 100, bg = "white",
    limitsize = FALSE
  )
}
