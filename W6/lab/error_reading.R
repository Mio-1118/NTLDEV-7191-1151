# Run after section 3 in the same R session.
# Read one grandstanding prediction error
error_rows <- which(gs_result$response != gs_result$truth)
k <- error_rows[1]
data.frame(
  doc_id = gs_parts$test$doc_id[k],
  reference = gs_result$truth[k],
  prediction = gs_result$response[k],
  prob = round(gs_result$prob[k, "Grandstanding"], 3),
  row.names = NULL)
cat(gs_parts$test$text[k], "\n")
