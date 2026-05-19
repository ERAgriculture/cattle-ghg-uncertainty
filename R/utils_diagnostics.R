compute_diag_trace <- function(co2e, n_checkpoints = 200L) {
  n      <- length(co2e)
  start  <- min(50L, n)
  idx    <- unique(round(seq(start, n, length.out = n_checkpoints)))
  cs  <- cumsum(co2e)
  list(
    iter         = idx,
    running_mean = cs[idx] / idx,
    running_lo   = sapply(idx, function(i) quantile(co2e[seq_len(i)], 0.025, names = FALSE)),
    running_hi   = sapply(idx, function(i) quantile(co2e[seq_len(i)], 0.975, names = FALSE)),
    final_mean   = mean(co2e),
    final_lo     = quantile(co2e, 0.025, names = FALSE),
    final_hi     = quantile(co2e, 0.975, names = FALSE)
  )
}

make_diag_badge <- function(label, tooltip_text, value_text, status) {
  badge_css <- switch(status,
    pass = "color:#166534; background:#DCFCE7; border:1px solid #22C55E;",
    warn = "color:#92400E; background:#FEF3C7; border:1px solid #F59E0B;",
    fail = "color:#991B1B; background:#FEE2E2; border:1px solid #EF4444;",
    info = "color:#1E40AF; background:#DBEAFE; border:1px solid #3B82F6;"
  )
  badge_label <- switch(status, pass = "Pass", warn = "Warn", fail = "Fail", info = "Info")
  div(
    style = paste0("background:#FFFFFF; border:1px solid #E0DDD5; border-radius:8px;",
                   "padding:14px 16px; display:flex; flex-direction:column; gap:6px;"),
    div(
      style = "display:flex; align-items:center; gap:6px;",
      tags$span(
        style = "font-size:0.78rem; color:#444; font-weight:600; text-transform:uppercase; letter-spacing:0.04em;",
        label
      ),
      bslib::tooltip(
        span(icon("circle-question"), style = "color:#6B6B6B; cursor:help; font-size:0.85rem;"),
        tooltip_text,
        placement = "top"
      )
    ),
    div(
      style = "display:flex; align-items:center; flex-wrap:wrap; gap:8px;",
      tags$span(style = "font-size:1.05rem; font-weight:700;", value_text),
      tags$span(
        style = paste0(badge_css,
                       "display:inline-block; font-weight:700; font-size:0.75rem;",
                       "border-radius:4px; padding:2px 10px;"),
        badge_label
      )
    )
  )
}
