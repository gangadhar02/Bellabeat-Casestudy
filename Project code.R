#Installing and loading required packages

library(skimr)
library(janitor)
library(lubridate)
library(openair)
library(ggpubr)
library(viridis)
library(ggrepel)

#Importing data (CSV's)

daily_activity <- read_csv("Downloads/Fitabase Data 4.12.16-5.12.16/dailyActivity_merged.csv")
daily_sleep <- read.csv(file= "Downloads/Fitabase Data 4.12.16-5.12.16/sleepDay_merged.csv")
hourly_steps <- read.csv("Downloads/Fitabase Data 4.12.16-5.12.16/hourlySteps_merged.csv")
hourly_intensities <- read.csv("Downloads/Fitabase Data 4.12.16-5.12.16/hourlyIntensities_merged.csv")
hourly_calories <- read.csv("Downloads/Fitabase Data 4.12.16-5.12.16/hourlyCalories_merged.csv")

#Viewing metadata

head(daily_activity)
skim_without_charts(daily_activity)

head(daily_sleep)
skim_without_charts(daily_sleep)

head(hourly_steps)
skim_without_charts(hourly_steps)

head(hourly_intensities)
skim_without_charts(hourly_intensities)

head(hourly_calories)
skim_without_charts(hourly_calories)

#Cleaning and uniting data as required for our analysis

#1.Counting total number of users in each table
n_distinct(daily_activity$Id)
n_distinct(daily_sleep$Id)
n_distinct(hourly_steps$Id)
n_distinct(hourly_intensities$Id)
n_distinct(hourly_calories$Id)

#2.Finding Duplicates 
sum(duplicated(daily_activity))
sum(duplicated(daily_sleep))
sum(duplicated(hourly_steps))
sum(duplicated(hourly_intensities))
sum(duplicated(hourly_calories))

#we can see know there are dulpicate observations in daily_sleep

#lets clean them 
daily_sleep <- distinct(daily_sleep)

#Verifying it 

sum(duplicated(daily_sleep))

#3.Counting N/A values 
colSums(is.na(daily_activity))
colSums(is.na(daily_sleep))
colSums(is.na(hourly_steps))
colSums(is.na(hourly_intensities))
colSums(is.na(hourly_calories))

#4.Making variable names consistent

daily_activity <- clean_names(daily_activity)
daily_sleep <- clean_names(daily_sleep)
hourly_steps <- clean_names(hourly_steps)
hourly_intensities <- clean_names(hourly_intensities)
hourly_calories <- clean_names(hourly_calories)

#5.Making Date and time consistent
daily_activity <- daily_activity %>%
  rename(date = activity_date) %>%
  mutate(date = as_date(date, format = "%m/%d/%Y"))

daily_sleep <- daily_sleep %>%
  rename(date = sleep_day) %>%
  mutate(date = as_date(date,format ="%m/%d/%Y %I:%M:%S %p"))

hourly_steps<- hourly_steps %>% 
  rename(date_time = activity_hour) %>% 
  mutate(date_time = as.POSIXct(date_time,format ="%m/%d/%Y %I:%M:%S %p"))

hourly_calories<- hourly_calories %>% 
  rename(date_time = activity_hour) %>% 
  mutate(date_time = as.POSIXct(date_time,format ="%m/%d/%Y %I:%M:%S %p"))

#Veryfing it
head(daily_activity, 3)
head(daily_sleep, 3)
head(hourly_steps,3)
head(hourly_calories,3)

#Merging Datasets as per our need
daily_activity.sleep <- right_join(daily_activity, daily_sleep, by=c ("id", "date"))

glimpse(daily_activity.sleep)

hourly_steps.calories <- full_join(hourly_steps, hourly_calories, by = c("id", "date_time"))
glimpse(hourly_steps.calories)

#Using Subsets to keep only necessary data
daily_activity.sleep <- select(daily_activity.sleep, `id`, `date`, `total_steps`, `calories`,
                               `total_minutes_asleep`)
head(daily_activity.sleep)

#ANALYZE PHASE
#Calculating avg daily steps of users

daily_average <- daily_activity.sleep %>%
  group_by(id) %>%
  summarise (mean_daily_steps = mean(total_steps), mean_daily_calories = mean(calories),
             mean_daily_sleep = mean(total_minutes_asleep))
head(daily_average)

#Classsifying and labeling based on  daily steps
user_type_steps <- daily_average %>%
  mutate(user_type = case_when(
    mean_daily_steps < 5000 ~ "sedentary",
    mean_daily_steps >= 5000 & mean_daily_steps < 7499 ~ "lightly active", 
    mean_daily_steps >= 7500 & mean_daily_steps < 9999 ~ "fairly active", 
    mean_daily_steps >= 10000 ~ "very active"
  ))
head(user_type_steps)
#Visualizing types of users with boxplot
ggplot(data = user_type_steps) +
  geom_boxplot(mapping = aes(x = user_type, y = mean_daily_steps, fill = user_type),
               outlier.color = "red", outlier.shape = 8) +
  coord_cartesian(ylim = c(2000,12000)) + labs(title = "Summary of User Types",
                                               y = "Average Daily Steps",
                                               x = "User Type") + theme(plot.title = element_text(hjust = 0.5, size = 15, face = "bold"),
                                                                        axis.text.x=element_text(size=12), 
                                                                        axis.text.y=element_text(size=10),
                                                                        axis.title.x=element_text(size=15),
                                                                        axis.title.y=element_text(size=15),
                                                                        legend.key.size=unit(1.2,"cm"))
options(repr.plot.width = 8,
        repr.plot.height = 8)

#Percentage of each usertype
steps_percent <- user_type_steps %>%
  group_by(user_type) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(user_type) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))

steps_percent$user_type <- factor(steps_percent$user_type , levels = c("very active", "fairly active", "lightly active", "sedentary"))

head(steps_percent)

#Percentage visualization in pie chart
pie <- ggplot(data = steps_percent, mapping = aes(x = "", y = total_percent, fill = user_type)) +
  geom_bar(stat = "identity")+
  coord_polar("y")+
  theme_void()+
  labs(title="User type distribution") + 
  theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"),
        legend.text = element_text(size = 10)) +
  scale_fill_discrete(name = "User Types") +
  geom_text(aes(label = labels),
            position = position_stack(vjust = 0.5))

pie + scale_fill_brewer("Pastel1") + theme_minimal()

#Sleep patttrens

#Categorising by Sleep
user_type_sleep <- daily_average %>%
  mutate(user_type = case_when(
    mean_daily_sleep >= 420 ~ "sufficient sleep",
    mean_daily_sleep < 420 ~ "insufficient sleep"
  ))

#Verifying
head(user_type_sleep)

#Calculating Percentage
sleep_percent <- user_type_sleep %>%
  group_by(user_type) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(user_type) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))

sleep_percent$user_type_sleep <- factor(sleep_percent$user_type , levels = c("sufficient sleep", "insufficient sleep"))

#Verifying
head(sleep_percent)

#Visualizing sleep data
ggplot(data = sleep_percent, mapping = aes(x = "", y = total_percent, fill = user_type)) +
  geom_bar(stat = "identity")+
  coord_polar("y")+
  theme_void()+
  labs(title="Proportion of users by sleep") + 
  theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"),
        legend.key.size=unit(0.8,"cm")) +
  scale_fill_manual(name = "User Types",
                    values = c("#EC6B56","#FFC154")) +
  geom_text(aes(label = labels),
            position = position_stack(vjust = 0.5))
options(repr.plot.width = 7,
        repr.plot.height = 6)

#Correlation between Steps, Sleep and Calories
daily_activity.sleep %>%
  mutate(activity_level = case_when(
    total_steps < 5000 ~ "sedentary",
    total_steps >= 5000 & total_steps < 7499 ~ "lightly active", 
    total_steps >= 7500 & total_steps < 9999 ~ "fairly active", 
    total_steps >= 10000 ~ "very active"), 
    sleep_type = case_when( total_minutes_asleep >= 420 ~ "sufficient sleep",
                            total_minutes_asleep < 420 ~ "insufficient sleep")) %>% 
  ggplot(mapping = aes(x = calories, y = total_steps)) + 
  geom_jitter(aes(color = activity_level, shape = sleep_type), size = 2.5) + 
  geom_smooth(method = 'loess',
              formula = 'y ~ x',
              se = FALSE) + 
  labs(title = "Correlation: Steps vs. Calories",
       subtitle = "Relationship between steps/day and calories burned per day", 
       x = "Calories Burned", 
       y = "Steps/Day")+
  guides(color = guide_legend("Activity Level"), 
         shape = guide_legend("Sleep Type")) + theme_minimal()  +
  theme(plot.title=element_text(size=21, face="bold"),
        plot.subtitle=element_text(size=15),
        axis.text.x=element_text(size=12), 
        axis.text.y=element_text(size=12),
        axis.title.x=element_text(size=18),
        axis.title.y=element_text(size=18),
        legend.key.size=unit(1,"cm"),
        legend.text = element_text(size = 11)) 

options(repr.plot.width = 9,
        repr.plot.height = 10)
#Avg steps and calories burnt per hour per weekday 

hourly_steps.calories <- hourly_steps.calories %>%
  separate(date_time, into = c("date", "time"), sep= " ") %>%
  mutate(date = ymd(date))

hourly_steps.calories <- hourly_steps.calories %>% 
  mutate(weekday = weekdays(date))

hourly_steps.calories$weekday <-ordered(hourly_steps.calories$weekday, levels=c("Monday", "Tuesday", "Wednesday", "Thursday",
                                                                                "Friday", "Saturday", "Sunday"))

hourly_steps.calories <- hourly_steps.calories %>% 
  right_join( user_type_steps, by = "id") %>% 
  mutate(weekday = factor(weekday,level = c('Monday', 'Tuesday', 'Wednesday','Thursday', 'Friday', 'Saturday', 'Sunday'))) %>% 
  group_by(user_type, time, weekday) %>% 
  summarise(steps = round(mean(step_total),2), 
            calories = round(mean(calories),2))

#Verifying
glimpse(hourly_steps.calories)
head(hourly_steps.calories)

#Visualizing Steps/Hour

options(repr.plot.width = 20,
        repr.plot.height = 12)

ggplot(hourly_steps.calories, aes(x = time,y = weekday)) + 
  geom_tile(aes(fill = steps)) +
  scale_fill_viridis(name="Hourly Steps",option ="plasma") +
  geom_text(aes(label = round(steps, digits = 0)), color = "black", size = 4) +
  theme_minimal(base_size = 14) +
  labs(title= ("Average Steps/Hour"), x='Time', y='Days')+
  theme(plot.title=element_text(size = 20, face = "bold"),
        axis.text.y=element_text(size=14),
        axis.text.x=element_text(size=14,angle = 90),
        axis.title.y=element_text(size=16),
        axis.title.x=element_text(size=16),
        legend.title=element_text(size=14),
        legend.text=element_text(size=14)) +
  guides(fill = guide_colourbar(barwidth = 0.45,barheight = 12))+
  facet_wrap(~user_type, nrow = 4)


ggplot(hourly_steps.calories, aes(x=time, y=steps, fill = steps))+ 
  scale_fill_gradient(low = "cyan", high = "purple")+
  geom_bar(stat = 'identity', show.legend = TRUE) +
  coord_flip() +
  ggtitle("Average Steps/Hour") +
  xlab("Hour") + ylab("Steps") +
  theme(plot.title=element_text(size = 20, face = "bold"),
        axis.text.y=element_text(size=7),
        axis.text.x=element_text(size=10,angle = 90),
        axis.title.y=element_text(size=16),
        axis.title.x=element_text(size=16),
        legend.title=element_text(size=14),
        legend.text=element_text(size=14))+
  facet_grid(user_type~weekday)

options(repr.plot.width = 14,
        repr.plot.height = 12)

#Visualizing Calories/Hour

ggplot(hourly_steps.calories, aes(x = time,y = weekday)) + 
  geom_tile(aes(fill = calories)) +
  scale_fill_viridis(name="Hourly Calories",option ="turbo") +
  geom_text(aes(label = round(steps, digits = 0)), color = "black", size = 4) +
  theme_minimal(base_size = 14) +
  labs(title= ("Average Calories/Hour"), x='Time', y='Days')+
  theme(plot.title=element_text(size = 20, face = "bold"),
        axis.text.y=element_text(size=14),
        axis.text.x=element_text(size=14,angle = 90),
        axis.title.y=element_text(size=16),
        axis.title.x=element_text(size=16),
        legend.title=element_text(size=14),
        legend.text=element_text(size=14)) +
  guides(fill = guide_colourbar(barwidth = 0.45,barheight = 12))+
  facet_wrap(~user_type, nrow = 4)
options(repr.plot.width = 20,
        repr.plot.height = 12)

ggplot(hourly_steps.calories, aes(x=time, y=calories, fill = calories))+ 
  scale_fill_gradient(low = "pink", high = "blue")+
  geom_bar(stat = 'identity', show.legend = TRUE) +
  coord_flip() +
  ggtitle("Average Calories/Hour") +
  xlab("Hour") + ylab("Calories") +
  theme(plot.title=element_text(size = 20, face = "bold"),
        axis.text.y=element_text(size=7),
        axis.text.x=element_text(size=10,angle = 90),
        axis.title.y=element_text(size=16),
        axis.title.x=element_text(size=16),
        legend.title=element_text(size=14),
        legend.text=element_text(size=14))+
  facet_grid(user_type~weekday)
options(repr.plot.width = 15,
        repr.plot.height = 12)

# Usage of smart device

# Get number of users used their devices each day:
users_bydate <- daily_activity.sleep %>% group_by(date) %>% 
  summarise(user_perday = sum(n()), .groups = "drop")

head(users_bydate)

#Plot a calendar heat map on total steps by day

calendarPlot(users_bydate,
             pollutant = "user_perday",
             year = 2016,
             month = 4:5,
             cex.lim = c(0.6, 1),
             main = "Number of Users Used Devices by Day",
             cols="BuPu", key.header = "n(Users)",
             key.position = "top")
options(repr.plot.width = 16,
        repr.plot.height = 12)

#Summary of users per day
summary(users_bydate$user_perday)


#Classyfing by usage of smart device

users_byid <- daily_activity.sleep %>%
  group_by(id) %>%
  summarize(days_used=sum(n())) %>%
  mutate(usage = case_when(
    days_used >= 1 & days_used <= 10 ~ "low use",
    days_used >= 11 & days_used <= 20 ~ "moderate use", 
    days_used >= 21 & days_used <= 31 ~ "high use", 
  ))

head(users_byid)

users_percent <- users_byid %>%
  group_by(usage) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(usage) %>%
  summarise(total_percent = (total / totals)*100)

users_percent$usage <- factor(users_percent$usage, levels = c("high use", "moderate use", "low use"))

head(users_percent)

# Computing the cumulative percentages (top of each rectangle)
users_percent$ymax = cumsum(users_percent$total_percent)

# Computing the bottom of each rectangle
users_percent$ymin = c(0, head(users_percent$ymax, n=-1))

# Computing label position
users_percent$labelPosition <- (users_percent$ymax + users_percent$ymin) / 2

# Computing label
users_percent$label <- paste0(users_percent$usage,
                              "\n value: ", users_percent$total_percent)
#Plot
ggplot(users_percent, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=usage)) +
  geom_rect() +
  geom_label( x=2, aes(y=labelPosition, label=label), size=6) +
  scale_color_brewer(palette=3) +
  coord_polar(theta="y") +
  xlim(c(-1, 4)) +
  theme_void() +
  scale_fill_manual(values = c("#9370DB","#B0CFDE","#728FCE"),
                    labels = c("High use - 21 to 31 days",
                               "Moderate use - 11 to 20 days",
                               "Low use - 1 to 10 days"))+
  labs(title="Daily use of smart device") + 
  theme(plot.title=element_text(size=20, face="bold"),
        legend.key.size=unit(1,"cm"),
        legend.text = element_text(size = 12),
        legend.title = element_text(size = 12))

options(repr.plot.width = 10,
        repr.plot.height = 10)

#Usage of smart device by minutes

daily_use_merged <- merge(daily_activity, users_byid, by=c ("id"))
head(daily_use_merged)

minutes_worn <- daily_use_merged %>% 
  mutate(total_minutes_worn = very_active_minutes+fairly_active_minutes+lightly_active_minutes+sedentary_minutes)%>%
  mutate (percent_minutes_worn = (total_minutes_worn/1440)*100) %>%
  mutate (worn = case_when(
    percent_minutes_worn == 100 ~ "All day",
    percent_minutes_worn < 100 & percent_minutes_worn >= 50~ "More than half day", 
    percent_minutes_worn < 50 & percent_minutes_worn > 0 ~ "Less than half day"
  ))

head(minutes_worn)

#New data frames for 4 types of users based on usage of smart device for easy viz

minutes_worn_percent<- minutes_worn%>%
  group_by(worn) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(worn) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))


minutes_worn_highuse <- minutes_worn%>%
  filter (usage == "high use")%>%
  group_by(worn) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(worn) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))

minutes_worn_moduse <- minutes_worn%>%
  filter(usage == "moderate use") %>%
  group_by(worn) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(worn) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))

minutes_worn_lowuse <- minutes_worn%>%
  filter (usage == "low use") %>%
  group_by(worn) %>%
  summarise(total = n()) %>%
  mutate(totals = sum(total)) %>%
  group_by(worn) %>%
  summarise(total_percent = total / totals) %>%
  mutate(labels = scales::percent(total_percent))

minutes_worn_highuse$worn <- factor(minutes_worn_highuse$worn, levels = c("All day", "More than half day", "Less than half day"))
minutes_worn_percent$worn <- factor(minutes_worn_percent$worn, levels = c("All day", "More than half day", "Less than half day"))
minutes_worn_moduse$worn <- factor(minutes_worn_moduse$worn, levels = c("All day", "More than half day", "Less than half day"))
minutes_worn_lowuse$worn <- factor(minutes_worn_lowuse$worn, levels = c("All day", "More than half day", "Less than half day"))

head(minutes_worn_percent)
head(minutes_worn_highuse)
head(minutes_worn_moduse)
head(minutes_worn_lowuse)

#Visualizing the above data 
ggarrange(
  ggplot(minutes_worn_percent, aes(x="",y=total_percent, fill=worn)) +
    geom_bar(stat = "identity", width = 1)+
    coord_polar("y", start=0)+
    theme_void()+
    theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5)) +
    scale_fill_manual(values = c("#728C00", "#6CC417", "#3EB489"))+
    geom_text(aes(label = labels),
              position = position_stack(vjust = 0.5), size = 3.5)+
    labs(title="Time worn per day", subtitle = "Total Users"),
  ggarrange(
    ggplot(minutes_worn_highuse, aes(x="",y=total_percent, fill=worn)) +
      geom_bar(stat = "identity", width = 1)+
      coord_polar("y", start=0)+
      theme_void()+
      theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"),
            plot.subtitle = element_text(hjust = 0.5), 
            legend.position = "none")+
      scale_fill_manual(values = c("#728C00", "#6CC417", "#3EB489"))+
      geom_text_repel(aes(label = labels),
                      position = position_stack(vjust = 0.5), size = 3)+
      labs(title="", subtitle = "High use - Users"), 
    ggplot(minutes_worn_moduse, aes(x="",y=total_percent, fill=worn)) +
      geom_bar(stat = "identity", width = 1)+
      coord_polar("y", start=0)+
      theme_void()+
      theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"), 
            plot.subtitle = element_text(hjust = 0.5),
            legend.position = "none") +
      scale_fill_manual(values = c("#728C00", "#6CC417", "#3EB489"))+
      geom_text(aes(label = labels),
                position = position_stack(vjust = 0.5), size = 3)+
      labs(title="", subtitle = "Moderate use - Users"), 
    ggplot(minutes_worn_lowuse, aes(x="",y=total_percent, fill=worn)) +
      geom_bar(stat = "identity", width = 1)+
      coord_polar("y", start=0)+
      theme_void()+
      theme(plot.title = element_text(hjust = 0.5, size=14, face = "bold"), 
            plot.subtitle = element_text(hjust = 0.5),
            legend.position = "none") +
      scale_fill_manual(values = c("#728C00", "#6CC417", "#3EB489"))+
      geom_text(aes(label = labels),
                position = position_stack(vjust = 0.5), size = 3)+
      labs(title="", subtitle = "Low use - Users"), 
    ncol = 3), 
  nrow = 2)
options(repr.plot.width = 8,
        repr.plot.height = 8)



















