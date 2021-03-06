#!/usr/bin/env Rscript
execution.start.time <- Sys.time()
td <- NULL
if(nchar(Sys.getenv("BUILD_DIR"))>0){
  setwd(Sys.getenv("BUILD_DIR"))
  td <- bindtextdomain(domain = "woc", dirname = file.path(Sys.getenv("BUILD_DIR"), "translations"))
} else {
  td <- bindtextdomain(domain = "woc", dirname = file.path(".", "translations"))
}
message(paste("The text domain was set to", td))

lang <- Sys.getenv("WOC_DECK_LOCALE")
if(nchar(lang)==0) lang <- "en"

message(paste("Rendering locale:", lang))

#######################
# Requirements & Setup
##
if (!require("pacman")) install.packages("pacman"); invisible(library(pacman))
invisible(p_load("dplyr", "xml2", "tidyr"))

os <- Sys.info()["sysname"]

woc.decks <- read_xml("./data/woc.xml")
greatoldones.decks <- read_xml("./data/woc.greatoldones.xml")

deck.families.meta <- read.csv(file="./data/deck.families.meta.csv", stringsAsFactors = FALSE)
rituals.meta <- read.csv(file="./data/rituals.meta.csv", stringsAsFactors = FALSE)
darkbonds.meta <- read.csv(file="./data/darkbonds.meta.csv", stringsAsFactors = FALSE)
cards.meta <- read.csv(file="./data/cards.meta.csv", stringsAsFactors = FALSE, colClasses = c("character", "character"))
greatoldones.meta <- read.csv(file="./data/greatoldones.meta.csv", stringsAsFactors = FALSE, colClasses = c("character", "character", "character"))
types.meta <- read.csv(file="./data/types.meta.csv", stringsAsFactors = FALSE)


picture.placeholder <- "picture.placeholder.png"
ritual.placeholder <- "icon.blank.png"
darkbond.placeholder <- "icon.blank.png"

source("./R/deck.parsing.R")
source("./R/greatoldones.parsing.R")

# TODO Add better internationalization support
switch(lang,
       en={
         language="English"
         charset="en_US.UTF-8"
       },
       it={
         language="Italian"
         charset="it_IT.UTF-8"
       }
)

####################
# Data Preparation
##

message(paste("Setting locale to", if(os %in% c("Linux", "Darwin", "Solaris")) {
  Sys.setlocale("LC_ALL", charset)
  Sys.setlocale("LC_MESSAGES", charset)
  Sys.getlocale()
  } else {
  Sys.setlocale("LC_ALL", language)
  }))
Sys.setenv(LANG = charset)

players.deck <- deck.parsing(woc.decks, domain = "woc")
greatoldones.deck <- greatoldones.parsing(greatoldones.decks, domain = "woc")

####################
# Deck Flattening
###

affected.columns.idx <- which(grepl("ritual\\.(study|transmutation|sacrifice).*", colnames(players.deck), perl = TRUE))
affected.columns.names <- colnames(players.deck)[affected.columns.idx]

ritual.sub <- as.data.frame(do.call(cbind, lapply(affected.columns.idx, function(i, deck){
  d <- gsub("FW Imm", "icon.forbidden-wisdom-immediate.png", deck[,i])
  d <- gsub("FW", "icon.forbidden-wisdom.png", d)
  d <- gsub("DM", "icon.dark-master.png", d)
  d <- gsub("EN", "icon.entity.png", d)
  d <- gsub("AS", "icon.alien-science.png", d)
  d <- gsub("Place", "icon.arcane-place.png", d)
  d <- gsub("NULL", "icon.blank.png", d)
  d <- gsub("Res", "icon.research.png", d)
  d <- gsub("Obs", "icon.obsession.png", d)
  d <- gsub("ES", "icon.elder-sign.png", d)
  return(d)
}, deck = players.deck)), stringsAsFactors = FALSE)
colnames(ritual.sub) <- affected.columns.names

standard.deck <- players.deck %>%
  left_join((deck.families.meta %>% select(family, background)), by = "family") %>%
  left_join(cards.meta, by = "card.id") %>%
  left_join(rituals.meta, by = "ritual.type") %>%
  left_join(darkbonds.meta, by = "darkbond.type") %>%
  left_join(types.meta, by = "type") %>%
  mutate(family.icon = gsub("background.", "icon.", background)) %>%
  mutate("*.back?" = "n") %>%
  mutate(picture = ifelse(is.na(picture), picture.placeholder, picture)) %>%
  mutate(ritual.icon = ifelse(is.na(ritual.icon), ifelse(is.na(darkbond.icon), ritual.placeholder, darkbond.icon), ritual.icon)) %>%
  #mutate(darkbond.icon = ifelse(is.na(darkbond.icon), darkbond.placeholder, darkbond.icon)) %>%
  mutate("ritual.study.trans.slash?" = ifelse(nchar(ritual.type)>0, "Y", "")) %>%
  mutate("ritual.trans.sacrifice.slash?" = ifelse(nchar(ritual.type)>0, "Y", "")) %>%
  select("card>" = card, card.id, type.icon, family, background, caption, family.icon, title, description, type, caption, knowledge.points, ritual.icon, darkbond.icon, picture, ends_with("?")) %>%
  cbind(ritual.sub) %>%
  mutate(BACK = "BACK") %>%
  mutate("*.front?" = "n") %>%
  left_join((deck.families.meta %>% select(family, background.back, family.back)), by = "family")

deck.file <- paste("./build/woc.deck", lang, "csv", sep=".")
write.csv(standard.deck, file = deck.file, row.names = FALSE, na = "")

standard.goo.deck <- greatoldones.deck %>%
  mutate("background.back?" = "n") %>%
  left_join(greatoldones.meta, by = "card.id") %>%
  left_join(darkbonds.meta, by = "darkbond.type") %>%
  mutate("box.1.prefix" = "I") %>%
  left_join(types.meta %>% select(type, "box.1.type" = "type.icon"), by = c("ritual.types.first" = "type")) %>%
  mutate("box.1.description" = ritual.description.first) %>%
  mutate("box.2.prefix" = "II") %>%
  left_join(types.meta %>% select(type, "box.2.type" = "type.icon"), by = c("ritual.types.second" = "type")) %>%
  mutate("box.2.description" = ritual.description.second) %>%
  mutate("BACK" = "BACK") %>%
  mutate("background.front?" = "n") %>%
  mutate("box.1.prefix_BACK" = "E") %>%
  left_join(types.meta %>% select(type, "box.1.type_BACK" = "type.icon"), by = c("ritual.types.evocation" = "type")) %>%
  mutate("box.1.description_BACK" = ritual.description.evocation) %>%
  mutate("box.2.prefix_BACK" = "IN") %>%
  left_join(types.meta %>% select(type, "box.2.type_BACK" = "type.icon"), by = c("ritual.types.influence" = "type")) %>%
  mutate("box.2.description_BACK" = ritual.description.influence) %>%
  select("card>" = card,
         "title>" = title,
         "darkbond.icon>" = darkbond.icon,
         "background.back?",
         background.front,
         box.1.prefix,
         box.1.type,
         box.1.description,
         box.2.prefix,
         box.2.type,
         box.2.description,
         "BACK",
         "background.front?",
         background.back,
         box.1.prefix_BACK,
         box.1.type_BACK,
         box.1.description_BACK,
         box.2.prefix_BACK,
         box.2.type_BACK,
         box.2.description_BACK)

goo.deck.file <- paste("./build/woc.goo.deck", lang, "csv", sep=".")
write.csv(standard.goo.deck, file = goo.deck.file, row.names = FALSE, na = "")

colors <- data.frame("frame.fill" = c("#ba0000", "#00ba00", "#0000ba", "#000000"), stringsAsFactors = FALSE)

standard.research.deck <- data.frame("card"=rep(1,6),
                                     rbind(
                                       data.frame(two = "Forbidden Wisdom", one = "Empty", back = "Obsession", stringsAsFactors = FALSE),
                                       data.frame(two = rep("Forbidden Wisdom", 2), one = c("Alien Science", "Dark Master"), back = "Obsession", stringsAsFactors = FALSE),
                                       data.frame(two = "Alien Science", one = "Empty", back = "Obsession", stringsAsFactors = FALSE),
                                       data.frame(two = "Alien Science", one = "Dark Master", back = "Obsession", stringsAsFactors = FALSE),
                                       data.frame(two = "Dark Master", one = "Empty", back = "Obsession", stringsAsFactors = FALSE)
                                     )) %>% 
  left_join((deck.families.meta %>% select(family, "family.one" = "family.back")), by = c("one"="family")) %>%
  left_join((deck.families.meta %>% select(family, "family.two>" = "family.back")), by = c("two"="family")) %>%
  left_join((deck.families.meta %>% select(family, "family.two" = "family.back")), by = c("back"="family")) %>%
  select("card", starts_with("family")) %>%
  mutate("background>" = "background.research.png") %>%
  mutate("BACK" = "BACK") %>%
  #mutate("frame?" = "y") %>%  
  mutate("background_BACK" = "background.obsession.png") %>%
  mutate("family.one?" = "n") %>%
  #mutate("frame?" = "y") %>%
  rename("card>" = "card")
  
standard.research.deck <- colors %>% 
  expand(standard.research.deck, colors= colors$frame.fill) %>%
  mutate("frame[style:fill]" = colors) %>%
  mutate("frame[style:fill]_BACK" = colors) %>%
  mutate("shade[style:fill]_BACK" = colors) %>%
  rename("shade[style:fill]" = colors)

standard.research.deck <- standard.research.deck[,c("card>",
                                                    "shade[style:fill]",
                                                    "frame[style:fill]",
                                                    "background>",
                                                    "family.one",
                                                    "family.two>",
                                                    "BACK",
                                                    "background_BACK",
                                                    "family.one?",
                                                    "family.two",
                                                    "shade[style:fill]_BACK",
                                                    "frame[style:fill]_BACK")] 
research.deck.file <- paste("./build/woc.research.deck", lang, "csv", sep=".")
write.csv(standard.research.deck, file = research.deck.file, row.names = FALSE, na = "")

