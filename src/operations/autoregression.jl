# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
function _ar(x; model=false)
  y = copy(x)
  goody = .!isnan.(x)
  yhat = vec(y[goody])
  ar = R"""
    ar_model <- ar($yhat)
    resid <- ar_model$resid
    x_mean <- ar_model$x.mean
    list(resid=resid, x_mean=x_mean)
  """
  ar = rcopy(R"list(resid=resid, x_mean=x_mean)")
  ϵ = replace(ar[:resid], missing => NaN)
  @. y[goody] = ϵ + ar[:x_mean]
  if model
    y, ar
  else
    y
  end
end
