#' @title Cosinor Model for Circadian Rhythmicity for the Whole Dataset
#' @description Extended cosinor model based on sigmoidally transformed cosine curve using anti-logistic transformation.This function is a whole dataset
#' wrapper for \code{ActExtendCosinor}.
#'
#' @param count.data \code{data.frame} of dimension n * (p+2) containing the
#' p dimensional activity data for all n subject days.
#' The first two columns have to be ID and Day. ID can be
#' either \code{character} or \code{numeric}. Day has to be \code{numeric} indicating
#' the sequence of days within each subject.
#' @param window The calculation needs the window size of the data. E.g window = 1 means each epoch is in one-minute window.
#' window size as an argument.
#' @param lower A numeric vector of lower bounds on each of the five parameters (in the order of minimum, amplitude, alpha, beta, acrophase) for the NLS. If not given, the default lower bound for each parameter is set to \code{-Inf}.
#' @param upper A numeric vector of upper bounds on each of the five parameters (in the order of minimum, amplitude, alpha, beta, acrophase) for the NLS. If not given, the default lower bound for each parameter is set to \code{Inf}
#' @param export_ts A Boolean to indicate whether time series should be exported (notice: it takes time and storage space to export time series data for all subject-days. Use this with caution. Suggest to only export time series for selected subjects)
#'
#'
#' @importFrom stats na.omit reshape
#' @importFrom dplyr group_by %>% do mutate
#'
#'
#' @return A \code{data.frame} with the following 11 columns
#' \item{ID}{ID}
#' \item{ndays}{number of days}
#' \item{minimum}{Minimum value of the of the function.}
#' \item{amp}{amplitude, a measure of half the extend of predictable variation within a cycle. This represents the highest activity one can achieve.}
#' \item{alpha}{It determines whether the peaks of the curve are wider than the troughs: when alpha is small, the troughs are narrow and the peaks are wide; when alpha is large, the troughs are wide and the peaks are narrow.}
#' \item{beta}{It dertermines whether the transformed function rises and falls more steeply than the cosine curve: large values of beta produce curves that are nearly square waves.}
#' \item{acrotime}{acrophase is the time of day of the peak in the unit of the time (hours)}
#' \item{F_pseudo}{Measure the improvement of the fit obtained by the non-linear estimation of the transformed cosine model}
#' \item{UpMesor}{Time of day of switch from low to high activity. Represents the timing of the rest- activity rhythm. Lower (earlier) values indicate increase in activity earlier in the day and suggest a more advanced circadian phase.}
#' \item{DownMesor}{Time of day of switch from high to low activity. Represents the timing of the rest-activity rhythm. Lower (earlier) values indicate decline in activity earlier in the day, suggesting a more advanced circadian phase.}
#' \item{MESOR}{A measure analogous to the MESOR of the cosine model (or half the deflection of the curve) can be obtained from mes=min+amp/2. However, it goes through the middle of the peak, and is therefore not equal to the MESOR of the cosine model, which is the mean of the data.}
#' \item{cosinor_ts}{Exported data frame with time, time over days, original time series, fitted time series using cosinor model from step 1, and fitted extended cosinor model from step 2}
#'
#' @export
#' @examples
#' counts_1 = example_activity_data$count[c(1:12),]
#' cos_all_1 = ActExtendCosinor_long(count.data = counts_1, window = 1, export_ts = TRUE)
#' counts_10 = cbind(counts_1[,1:2],
#' as.data.frame(t(apply(counts_1[,-c(1:2)], 1,
#' FUN = bin_data, window = 10, method = "average"))))
#' cos_all_10 = ActExtendCosinor_long(count.data = counts_10, window = 10, export_ts = FALSE)
#'


ActExtendCosinor_long = function(
  count.data,
  window = 1,
  lower = c(0, 0, -1, 0, -3), ## min, amp, alpha, beta, phi
  upper = c(Inf, Inf, 1, Inf, 27),
  export_ts = FALSE
){
  ID = value = . = NULL
  rm(list = c("ID", "value", "."))

  long.count = reshape(count.data, varying = names(count.data)[3:ncol(count.data)],direction = "long",
                       timevar = "Time",idvar = c("ID","Day"),v.names = "values",new.row.names = c(1:((ncol(count.data)-2)*nrow(count.data))))
  long.count = long.count[
    with(long.count, order(ID, Day,Time)),
  ]


  result= long.count  %>% group_by(ID) %>% do(out = ActExtendCosinor(.$values,
                                                               window = window, lower = lower, upper = upper,export_ts = export_ts))


  ## Exporting the parameters

  out = unlist(sapply(result$out, function(x) x[1]))
  params = as.data.frame(matrix(out,ncol = 10,byrow = T))
  names(params) = gsub("params.","", names(out)[1:10])
  params = params %>% mutate(ID = result$ID)
  names(params)[1:9] = paste0(names(params)[1:9],"_",window)
  params = params[,c(11,10,1:9)]

  ## Exporting the parameters
  if(export_ts){
    data_ts = sapply(result$out, function(x) x[2])
    names(data_ts) = result$ID
    ret = list("params" = params,"cosinor_ts" = data_ts)
  }else{
   ret = params
  }

  return(ret)

}
