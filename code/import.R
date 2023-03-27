source(here::here("code/setup.R"))



# Putting together a subset of paday loan rule comments for Tayo that we know are submitted by organizations

####  CFPB DATA FROM hand-coded googles heets ####
library(googledrive)
library(googlesheets4)

email = "devin.jl@gmail.com"

gs4_auth(email)
drive_auth(email)

sheets = c("1GCz6ewgJGUYMo2mN6BdPoECMoT34xaumoyR9YP51pNw",
           "1kOXZZDTrrOPfRV_vnc5GoGVBMI94L9WnqpGGGmApPTw")

# read all as char
read_sheet_c <- . %>% read_sheet(col_types = "c")

# init
d1 <- read_sheet_c(sheets[1])

# map
d <- map_dfr(sheets, possibly(read_sheet_c, otherwise = head(d1)))

# remove extra white space
d %<>% mutate_all(str_squish)

unique(d$docket_id)

####  CFPB DATA FROM SQLITE DATABASE ####
library(DBI)
library(RSQLite)

# Database locations
new_data_location <- here::here("data", "comment_metadata_CFPB_df.sqlite")

## Load new Data ##

#get new data connection
con = dbConnect(SQLite(), dbname= new_data_location)

#get all tables
dbListTables(con)

# * is all
Query <- dbSendQuery(con, "SELECT * FROM comments") 

# Load ALL data
data <- dbFetch(Query, n = -1)

dbDisconnect() 



# JOIN CODED AND SQL DATA 
data %<>% mutate(document_id = comment_id)

d %<>% full_join(data %>%
                   select(-comment_url, -organization)) %>%
  mutate(comment_type = str_to_lower(comment_type)) %>%
  filter(comment_type == "org")

d %<>% select(
  starts_with("submitter"),
  starts_with("comment"),
  starts_with("org"),
  starts_with("coalition"),
  starts_with("docket"),
  ends_with("url")
  )

# FOR NOW, ONLY CFBP-2016-0025 IS IN BOTH 
d %<>% filter(docket_id == "CFPB-2016-0025")


# Payday loan rule subset 
d %>% 
  write.csv(file = here("data", "CFPB-2016-0025-org-comments.csv"))


data %>% 
  filter(nchar(submitter_name)>3) %>% 
  filter(docket_id == "CFPB-2016-0025") %>% 
  select(organization, submitter_name, 
         #docket_id, 
         comment_id) %>% 
  write_csv(file = here("data", "CFPB-2016-0025-comment-submitter-names.csv"))

