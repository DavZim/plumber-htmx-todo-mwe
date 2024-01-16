library(plumber)

# download tailwindcss from https://github.com/tailwindlabs/tailwindcss/releases
# compile css
q <- "./tailwindcss-linux-x64 -i style/custom.css -o www/tailwind.css"
tw_res <- try(system(q), silent = TRUE)
if (inherits(tw_res, "try-error"))
  message("Could not execute tailwindcss CLI, this might lead to outdated CSS.")

pr("plumber.R") |>
  pr_hook("preroute", function(req) {
    cat(paste(req$REQUEST_METHOD, req$PATH_INFO, "\n"))
  }) |>
  pr_run(port = 8080)