# wrapper around glue::glue to read in an html template file and fill values
fglue <- function(file, ..., .envir = parent.frame()) {
  glue::glue(paste(readLines(file), collapse = "\n"),
             ..., .envir = .envir, .null = "")
}

df_file <- "data.RDS"
if (file.exists(df_file)) {
  df <- readRDS(df_file)
  last_id <- if (nrow(df) == 0) 0 else max(df$id)
} else {
  df <- data.frame(id = integer(), title = character(), is_checked = logical())
  last_id <- 0
}

# static files in www so we have access to css etc
#* @assets ./www /
list()

#* @get /
#* @serializer html
function() {
  fglue("templates/index.html")
}

#* @get /list
#* @serializer html
function() {
  if (nrow(df) == 0) return("")

  res <- apply(df, 1, function(x) {
    fglue("templates/todo-item.html",
          ID = x[["id"]],
          TITLE = x[["title"]],
          CHECKED = x[["is_checked"]],
          NEW = FALSE)
  })
  res <- paste(res, collapse = "\n")
  return(res)
}

#* @post /add
#* @serializer html
function(req) {
  last_id <<- last_id + 1

  title <- req$args$title
  is_checked <- FALSE
  new_todo <- data.frame(
    id = last_id,
    title = title,
    is_checked = is_checked
  )
  df <<- rbind(df, new_todo)
  saveRDS(df, df_file)
  cat(sprintf("  - Updated file: added ID <%s> -> title '%s'\n",
              last_id, title))

  res <- fglue("templates/todo-item.html",
               ID = last_id,
               TITLE = title,
               CHECKED = is_checked,
               NEW = TRUE)
  return(res)
}


#* @post /edit/<id>
#* @serializer html
function(req) {
  # get params of req
  id <- as.numeric(req$args$id)
  title <- req$args$title

  # edit df
  df[df$id == id, "title"] <<- title
  saveRDS(df, df_file)
  cat(sprintf("  - Updated file: ID <%s> -> title '%s'\n", id, title))

  # return new title
  fglue("templates/todo-item.html",
        ID = id,
        TITLE = title,
        CHECKED = FALSE,
        NEW = TRUE)
}

#* @post /toggle/<id>
#* @serializer html
function(req) {
  # get params of req
  id <- as.numeric(req$args$id)
  is_checked <- isTRUE(req$args$is_checked == "on")

  # edit df
  df[df$id == id, "is_checked"] <<- is_checked
  saveRDS(df, df_file)
  cat(sprintf("  - Updated file: ID <%s> is checked: %s\n", id, is_checked))

  # return new title
  fglue("templates/todo-item.html",
        ID = id,
        TITLE = df[df$id == id, "title"],
        CHECKED = is_checked,
        NEW = TRUE)
}

#* @delete /delete/<id>
#* @serializer html
function(req) {
  # get params of req
  id <- as.numeric(gsub("^%20", "", req$args$id))
  # edit df
  df <<- df[df$id != id, ]
  saveRDS(df, df_file)
  cat(sprintf("  - Updated file: ID <%s> -> DELETED\n", id))

  # return empty string to remove from DOM
  ""
}
