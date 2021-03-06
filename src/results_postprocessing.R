library("stringr")

# clean condition string returned by partykit package
clean_condition_str <- function(raw_str){
  str_splits <- str_split(raw_str, pattern=" & ", simplify = TRUE)
  cleaned_condition <- ""
  attr_considered <- character()
  for(i in length(str_splits[,]):1){
    current_attr <- word(str_splits[,i], 1)
    cont_smaller <- grepl("<=", str_splits[,i])
    cont_larger <- grepl(">", str_splits[,i])
    if(cont_smaller){
      current_attr <- paste(current_attr, "<")
    }
    if(cont_larger){
      current_attr <- paste(current_attr, ">")
    }
    if(current_attr %in% attr_considered){
      next
    }
    attr_considered <- c(attr_considered, current_attr)
    cleaned_condition <- paste(cleaned_condition, str_splits[,i], "; ", sep="")   
  }
  pats <- c('"NA", |, "NA"|"|%')
  cleaned_condition <- str_replace_all(cleaned_condition, pats, "")
  cleaned_condition <- str_replace_all(cleaned_condition, "c\\(", "{")
  cleaned_condition <- str_replace_all(cleaned_condition, "\\)", "}")
  cleaned_condition <- sapply(strwrap(cleaned_condition, width = 100, simplify = FALSE),
                              paste, collapse = "\n")
  return(cleaned_condition)}


# vectorize function "clean_condition_str"
v_clean_condition_str <- Vectorize(clean_condition_str)


# remove duplicates and clean results
clean_results <- function(group_size, group_condition, disparity_magnitude, disparity_confidence, tree_id){
  results_df <- data.frame(group_size, group_condition, disparity_magnitude, disparity_confidence, tree_id)
  results_df$group_condition <- v_clean_condition_str(results_df$group_condition)
  results_df <- results_df[!duplicated(results_df$group_condition), ]
  return(results_df)
}


# correct p-values of results for multiple hypothesis testing
correct_pval <- function(results_df){
  results_df$disparity_confidence <- p.adjust(results_df$disparity_confidence, p.adjust.methods[2])
  return(results_df)
}


# rank results according to either magnitude or confidence
rank_results <- function(results_df, ranking){
  if (ranking == "confidence"){
    results_df <- results_df[order(results_df$disparity_confidence),]
  } else if(ranking == "magnitude"){
    results_df <- results_df[order(-results_df$disparity_magnitude),]
  } else{
    stop(
      paste("Ranking mechanism \"", ranking, 
            "\" is not implemented. Try \"confidence\" or \"magnitude\".", sep=""))
  }
  return(results_df)
}