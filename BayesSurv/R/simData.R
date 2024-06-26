#' @title Simulated data set
#'
#' @description
#' Simulated data set for a quick test. The data set is a list with six
#' components:  covariates \code{"X"}, survival times \code{"time"}, 
#' event status \code{"status"}. The R code for generating the simulated data 
#' is given in the Examples.
#'
#'
#' @import MASS
#' @import survival
#' @import mvtnorm
#'
#' @examples
#' # Load the example dataset
#' data("simData", package = "BayesSurv")
#' str(simData)
#'
#' # ===============
#' # The code below is to show how to generate the dataset "simData.RData"
#' # ===============
#'
#' requireNamespace("MASS", quietly = TRUE)
#' requireNamespace("survival", quietly = TRUE)
#' requireNamespace("mvtnorm", quietly = TRUE)
#' 
#' set.seed(123)
#' p = 200
#' trueBeta = runif(20, min=-1, max=1)
#' trueBeta = c(1,1,1,1,-1,-1,-1)
#' trueBeta = c(trueBeta, rep(0, p - length(trueBeta)))
#' 
#' sigma = diag(p)
#' block = matrix(rep(.5,9), nrow=3); diag(block) = 1
#' sigma[1:3, 1:3] = block#sigma[4:6, 4:6] = sigma[7:9, 7:9] = block
#' 
#' sigma = diag(p)
#' block = matrix(rep(.5,15*15), nrow=15); diag(block) = 1
#' sigma[1:15, 1:15] = block
#' 
#' truePara = list("beta" = trueBeta, "sigma" = sigma)
#' mcmc_iterations = 1000
#' graph="true"
#' seed = sample(1:10e7, 1)
#' set.seed(seed)
#' 
#' truePara$gamma = as.numeric(truePara$beta != 0)
#' 
#' # simulate underlying graph of the covariance matrix
#' G = matrix(data = as.numeric( truePara$sigma != 0 ), nrow=p, ncol=p)
#' diag(G) = 0 
#' sigma = truePara$sigma
#' 
#' if (grepl("true", graph, fixed=TRUE)) {
#'   G = matrix(data = as.numeric( sigma != 0 ), nrow=p, ncol=p)
#'   diag(G) = 0  
#' }
#' 
#' if (grepl("empty", graph, fixed=TRUE))
#'   G = matrix(0, nrow=p, ncol=p)  
#' 
#' priorParaPooled = list(
#'   #"eta0"   = eta0,                   # prior of baseline hazard
#'   #"kappa0" = kappa0,                 # prior of baseline hazard
#'   "c0"     = 2,                      # prior of baseline hazard
#'   "tau"    = 0.0375,                 # standard deviation for prior of regression coefficients
#'   "cb"     = 20,                     # standard deviation for prior of regression coefficients
#'   "pi.ga"  = 0.02, #0.5, ga.pi,      # prior variable selection probability for standard Cox models
#'   "a"      = -4, #a0,                # hyperparameter in MRF prior
#'   "b"      = 0.1, #b0,               # hyperparameter in MRF prior
#'   "G"       = G
#' ) 
#' 
#' n = 100
#' p = length(truePara$beta)
#' 
#' ########################### Predefined Functions 'sim.surv()' & 'sim.data.fun()'
#' 
#' #simulated gene expression data, for two subgroups, split into test and training data
#' sim.surv = function(X, beta, surv.e, surv.c, n){
#'   
#'   # simulate event times from Weibull distribution
#'   dt = (-log(runif(n)) * (1/surv.e$scale) * exp(-X %*% beta))^(1/surv.e$shape)
#'   
#'   # simulate censoring times from Weibull distribution
#'   cens = rweibull(n, shape = surv.c$shape, scale = ((surv.c$scale)^(-1/surv.c$shape)))
#'   
#'   # observed time and status for each observation
#'   status = ifelse(dt <= cens, 1, 0)
#'   time = pmin(dt, cens)
#'   
#'   return(list(as.numeric(status), as.numeric(time)))
#' }
#' 
#' sim.data.fun = function(n, p, surv.e, surv.c, beta1.p, beta2.p, cov_matrix){
#'   
#'   p.e = length(beta1.p) # Number of prognostic variables 
#'   
#'   # True effects in each subgroup
#'   beta1 = c( beta1.p, rep(0,p-p.e) )
#'   beta2 = c( beta2.p, rep(0,p-p.e) )
#'   
#'   # Covariance matrix in both subgroups
#'   #sigma = diag(p)
#'   #block = matrix(rep(.5,9), nrow=3); diag(block) = 1
#'   #sigma[1:3, 1:3] = sigma[4:6, 4:6] = sigma[7:9, 7:9] = block
#'   
#'   sigma = cov_matrix
#'   
#'   # Sample gene expression data from multivariate normal distribution
#'   X1 = MASS::mvrnorm(n, rep(0,p), sigma)  
#'   X2 = MASS::mvrnorm(n, rep(0,p), sigma)
#'   
#'   # Simulate survival data for both subgroups
#'   surv1 = sim.surv(X1, beta1, surv.e[[1]], surv.c[[1]], n) 
#'   surv2 = sim.surv(X2, beta2, surv.e[[2]], surv.c[[2]], n) 
#'   
#'   # Combine training and test data of both subgroups
#'   data1 = list("X" = X1, "time" = surv1[[2]], "status" = surv1[[1]])
#'   data2 = list("X" = X2, "time" = surv2[[2]], "status" = surv2[[1]])
#'   Data = list("subgroup1" = data1, "subgroup2" = data2)
#'   
#'   # Scale covariates using parameters of training data
#'   sd.X = lapply(Data, function(xx) apply(xx$X,2,sd))  
#'   for(g in 1:length(Data)){
#'     Data[[g]]$X <- scale(Data[[g]]$X, scale=sd.X[[g]])
#'   }
#'   
#'   # Unscaled covariates (for Pooled model):
#'   Data[[1]]$X.unsc = X1
#'   Data[[2]]$X.unsc = X2
#'   Data[[1]]$trueB = beta1
#'   Data[[2]]$trueB = beta2
#'  
#'   return(Data)
#' }
#'
#' Surv.e <- Surv.c <- list(NULL, NULL)
#' # Weibull event distribution for 2 subgroups
#' Surv.e[[1]]$scale = 1.147817e-08
#' Surv.e[[1]]$shape = 8.605045
#' Surv.e[[2]]$scale = 0.0001460504
#' Surv.e[[2]]$shape = 4.791238
#' 
#' # Weibull cencoring distribution for 2 subgroups
#' Surv.c[[1]]$scale = 1.147817e-08
#' Surv.c[[1]]$shape = 8.605045
#' Surv.c[[2]]$scale = 0.0001460504
#' Surv.c[[2]]$shape = 4.791238
#' 
#' simData = sim.data.fun(n = n, p = p, surv.e = Surv.e, surv.c = Surv.c, 
#'   beta1.p = truePara$beta, beta2.p = truePara$beta, 
#'   cov_matrix = truePara$sigma)
#' simData$G = G
#' save(simData, file = "simData.rda")
#'
"simData"
