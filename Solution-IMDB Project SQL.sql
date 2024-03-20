# Segment 1: Database - Tables, Columns, Relationships


# What are the different tables in the database and how are they connected to each other in the database?

-- Table 1: Director Mapping:

-- Connected to the Movie table through the Movie_id column.
-- Connected to the Names table through the name_id column.

-- Table 2: Genre:

-- Connected to the Movie table through the Movie_id column.

-- Table 3: Movie:

-- Connected to the Director Mapping table through the Movie_id column.
-- Connected to the Genre table through the Movie_id column.

-- Table 3: Names:

-- Connected to the Director Mapping table through the name_id column.

-- Table 4: Ratings:

-- Connected to the Movie table through the movie_id column.

-- Table 5: Role Mapping:

-- Connected to the Movie table through the movie_id column.
-- Connected to the Names table through the name_id column.

# Find the total number of rows in each table of the schema.

SELECT TABLE_NAME, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'imdb';

# Identify which columns in the movie table have null values.

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Movie' AND TABLE_SCHEMA = 'IMDB' AND IS_NULLABLE = 'YES';

# Segment 2: Movie Release Trends

# Determine the total number of movies released each year and analyse the month-wise trend

SELECT year, COUNT(*) AS total_movies FROM Movie             # Year wise analysis
GROUP BY year
ORDER BY year;

SELECT EXTRACT(MONTH FROM date_published) AS month, COUNT(*) AS total_movies   # Month wise trend
FROM Movie
GROUP BY EXTRACT(MONTH FROM date_published)
ORDER BY EXTRACT(MONTH FROM date_published);
 
# Calculate the number of movies produced in the USA or India in the year 2019.

SELECT COUNT(*) AS total_movies_US_or_India
FROM Movie
WHERE (country = 'USA' OR country = 'India') AND year = 2019;

# Segment 3: Production Statistics and Genre Analysis

SELECT DISTINCT Genre
FROM Genre;

# Identify the genre with the highest number of movies produced overall.

SELECT Genre, COUNT(*) AS total_movies
FROM Genre
GROUP BY Genre
ORDER BY total_movies DESC
LIMIT 3;

# Determine the count of movies that belong to only one genre.

SELECT COUNT(*) AS count_movies_one_genre
FROM (
SELECT Movie_id FROM Genre
GROUP BY Movie_id
HAVING COUNT(*) = 1) AS subquery;

# Calculate the average duration of movies in each genre

SELECT g.Genre, round(AVG(m.duration),2) AS average_duration
FROM Genre g
JOIN Movie m ON g.Movie_id = m.id
GROUP BY g.Genre;

# Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced

SELECT Genre, genre_rank
FROM (SELECT Genre, RANK() OVER (ORDER BY total_movies DESC) AS genre_rank
FROM (SELECT Genre, COUNT(*) AS total_movies FROM Genre
GROUP BY Genre) AS genre_counts) AS ranked_genres
WHERE Genre = 'thriller';

# Segment 4: Ratings Analysis and Crew Members

# Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).

SELECT
MIN(avg_rating) AS min_avg_rating,
MAX(avg_rating) AS max_avg_rating,
MIN(total_votes) AS min_total_votes,
MAX(total_votes) AS max_total_votes,
MIN(median_rating) AS min_median_rating,
MAX(median_rating) AS max_median_rating
FROM Ratings;

# Identify the top 10 movies based on average rating.

select m.title, subquery.avg_rating from movie m
inner join
(select * from ratings
order by avg_rating desc
limit 10) subquery on m.id = subquery.movie_id;

# Summarise the ratings table based on movie counts by median ratings

select median_rating, count(*) as movie_count from ratings
group by median_rating
order by movie_count desc;


# Identify the production house that has produced the most number of hit movies (average rating > 8)

SELECT m.production_company, COUNT(*) AS hit_movie_count
FROM Movie m
JOIN Ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 8 and m.production_company is not null
GROUP BY m.production_company
ORDER BY hit_movie_count DESC
LIMIT 1;

# Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.

SELECT g.Genre, COUNT(*) AS movie_count FROM Genre g
JOIN Movie m ON g.Movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
WHERE m.country = 'USA'
AND YEAR(m.date_published) = 2017
AND MONTH(m.date_published) = 3
AND r.total_votes > 1000
GROUP BY g.Genre;

#-	Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.

SELECT g.Genre, m.title, r.avg_rating
FROM Movie m
JOIN Genre g ON m.id = g.Movie_id
JOIN Ratings r ON m.id = r.movie_id
WHERE m.title LIKE 'The%' AND r.avg_rating > 8
order by g.genre;

# Segment 5: Crew Analysis

# Identify the columns in the names table that have null values

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Names'
AND TABLE_SCHEMA = 'IMDB'
AND IS_NULLABLE = 'YES';

# Determine the top three directors in the top three genres with movies having an average rating > 8

SELECT genre_subquery.Genre, director_subquery.director_name, director_subquery.movie_count
FROM(SELECT g.Genre FROM Genre g
JOIN
Movie m ON g.Movie_id = m.id
JOIN
Ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 8
GROUP BY g.Genre
ORDER BY COUNT(*) DESC
LIMIT 3
) AS genre_subquery
JOIN
(SELECT g.Genre, n.name AS director_name, COUNT(*) AS movie_count,
ROW_NUMBER() OVER (PARTITION BY g.Genre ORDER BY COUNT(*) DESC) AS row_num
FROM Names n
JOIN Director_Mapping dm ON n.id = dm.name_id
JOIN Movie m ON dm.Movie_id = m.id
JOIN Genre g ON m.id = g.Movie_id
JOIN Ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 8
GROUP BY g.Genre, n.name
ORDER BY g.Genre, COUNT(*) DESC
) AS director_subquery ON genre_subquery.Genre = director_subquery.Genre
WHERE director_subquery.row_num <= 3
ORDER BY genre_subquery.Genre, director_subquery.movie_count DESC;

# Find the top two actors whose movies have a median rating >= 8

SELECT n.name, COUNT(*) AS movie_count
FROM Names n
JOIN Role_Mapping rm ON n.id = rm.name_id
JOIN Ratings r ON rm.movie_id = r.movie_id
WHERE r.median_rating >= 8
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 2;

# Identify the top three production houses based on the number of votes received by their movies

SELECT m.production_company, SUM(r.total_votes) AS total_votes FROM Movie m
JOIN Ratings r ON m.id = r.movie_id
GROUP BY m.production_company
ORDER BY total_votes DESC
LIMIT 3;

# Rank actors based on their average ratings in Indian movies released in India

SELECT n.name AS actor_name, round(AVG(r.avg_rating), 2) AS average_rating FROM Names n
JOIN Role_Mapping rm ON n.id = rm.name_id
JOIN Movie m ON rm.movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
WHERE m.country = 'India' 
GROUP BY n.name
ORDER BY average_rating DESC;

# Identify the top five actresses in Hindi movies released in India based on their average ratings

SELECT n.name AS actress_name, round(AVG(r.avg_rating), 2) AS average_rating FROM Names n
JOIN Role_Mapping rm ON n.id = rm.name_id
JOIN Movie m ON rm.movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
WHERE m.country = 'India' AND m.languages LIKE '%Hindi%' AND rm.category = 'actress'
GROUP BY n.name
ORDER BY average_rating DESC
LIMIT 5;

# Segment 6: Broader Understanding of Data

# Classify thriller movies based on average ratings into different categories

SELECT m.title, r.avg_rating,
CASE
WHEN r.avg_rating >= 9 THEN 'Excellent'
WHEN r.avg_rating >= 8 THEN 'Very Good'
WHEN r.avg_rating >= 7 THEN 'Good'
WHEN r.avg_rating >= 6 THEN 'Above Average'
ELSE 'Below Average' 
END AS rating_category
FROM Movie m
JOIN Genre g ON m.id = g.Movie_id
JOIN Ratings r ON m.id = r.movie_id
WHERE g.Genre = 'thriller'
ORDER BY r.avg_rating DESC;

# analyse the genre-wise running total and moving average of the average movie duration.

SELECT g.Genre, m.duration,
SUM(m.duration) OVER (PARTITION BY g.Genre ORDER BY m.duration) AS running_total,
round(AVG(m.duration) OVER (PARTITION BY g.Genre ORDER BY m.duration ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS moving_average
FROM Genre g
JOIN Movie m ON g.Movie_id = m.id;

# Identify the five highest-grossing movies of each year that belong to the top three genres

SELECT year, Genre, title, worlwide_gross_income
FROM (SELECT m.year, g.Genre, m.title, m.worlwide_gross_income,
ROW_NUMBER() OVER (PARTITION BY m.year, g.Genre ORDER BY m.worlwide_gross_income DESC) AS rank_
FROM Movie m
JOIN Genre g ON m.id = g.Movie_id
WHERE g.Genre IN (SELECT Genre FROM (SELECT Genre, COUNT(*) AS genre_count FROM Genre
GROUP BY Genre
ORDER BY genre_count DESC
LIMIT 3) AS top_genres) AND m.worlwide_gross_income IS NOT NULL) AS ranked_movies
WHERE rank_ <= 5
ORDER BY year, Genre, worlwide_gross_income DESC;


# Determine the top two production houses that have produced the highest number of hits among multilingual movies.

SELECT m.production_company, COUNT(*) AS hit_count
FROM Movie m
JOIN Ratings r ON m.id = r.movie_id
WHERE m.languages <> 'English'         -- Exclude English-only movies
AND r.avg_rating >= 8                  -- Consider hits with an average rating >= 8
AND m.production_company is not null   -- excluding null values in the Production company column
GROUP BY m.production_company
ORDER BY hit_count DESC
LIMIT 2;


# Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.

SELECT n.name AS actress_name, COUNT(*) AS super_hit_count
FROM Names n
JOIN Role_Mapping rm ON n.id = rm.name_id
JOIN Movie m ON rm.movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
JOIN Genre g ON m.id = g.Movie_id
WHERE r.avg_rating > 8 AND g.Genre = 'drama' AND rm.category = 'actress'
GROUP BY n.name
ORDER BY super_hit_count DESC
LIMIT 3;

# Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.

SELECT n.name AS director_name, COUNT(DISTINCT dm.Movie_id) AS movie_count, round(AVG(m.duration), 2) AS average_duration,
round(AVG(r.avg_rating), 2) AS average_rating, MAX(r.avg_rating) AS highest_rating, MIN(r.avg_rating) AS lowest_rating
FROM Names n
JOIN Director_Mapping dm ON n.id = dm.name_id
JOIN Movie m ON dm.Movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 9;


# The below questions are not a part of the problem statement but should be included after the their completion to test their understanding

# Determine the average duration of movies released by Bolly Movies compared to the industry average.

SELECT AVG(duration) AS bolly_movies_average_duration, (SELECT AVG(duration) FROM Movie) AS industry_average_duration FROM Movie
WHERE languages = 'Hindi' and duration is not null;


# Analyse the correlation between the number of votes and the average rating for movies produced by Bolly Movies.

SELECT round(AVG(total_votes), 2) AS average_votes, round(AVG(avg_rating),2) AS average_rating,
round((SUM(total_votes * avg_rating) - SUM(total_votes) * SUM(avg_rating) / COUNT(*)) / 
SQRT((SUM(total_votes * total_votes) - SUM(total_votes) * SUM(total_votes) / COUNT(*)) *
(SUM(avg_rating * avg_rating) - SUM(avg_rating) * SUM(avg_rating) / COUNT(*))),4) AS correlation
FROM Movie
JOIN Ratings ON Movie.id = Ratings.movie_id
WHERE languages = 'Hindi';

# Find the production house that has consistently produced movies with high ratings over the past three years

SELECT m.production_company, AVG(r.avg_rating) AS average_rating
FROM Movie m
JOIN Ratings r ON m.id = r.movie_id
WHERE m.year >= YEAR(DATE_SUB(CURDATE(), INTERVAL 3 YEAR)) -- Consider the past three years
GROUP BY m.production_company
HAVING COUNT(DISTINCT m.year) = 3 -- Only consider production houses with movies in all three years
AND AVG(r.avg_rating) >= 8 -- Filter for high ratings
ORDER BY average_rating DESC;

# Identify the top three directors who have successfully delivered commercially successful movies with high ratings

SELECT n.name AS director_name, COUNT(*) AS movie_count, AVG(r.avg_rating) AS average_rating, SUM(m.worlwide_gross_income) AS total_gross_income
FROM Names n
JOIN Director_Mapping dm ON n.id = dm.name_id
JOIN Movie m ON dm.Movie_id = m.id
JOIN Ratings r ON m.id = r.movie_id
WHERE m.worlwide_gross_income IS NOT NULL
GROUP BY n.name
HAVING COUNT(*) >= 2 -- Filter for directors with at least 2 movies
AND AVG(r.avg_rating) >= 8 -- Filter for high ratings
ORDER BY total_gross_income DESC, count(*) desc
LIMIT 10;


# Based on the Analysis of the provided Data: Below are some of the Observations that Bollywood should focus on venture into Global Markets

# to provide with the suggestions I have done some additional analysis. The Queries for these additional analysis are below

# Genre wise Avg World wide income

SELECT Genre, round(avg(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))),2) AS total_gross_income
FROM Movie
JOIN Genre ON Movie.id = Genre.Movie_id
WHERE worlwide_gross_income IS NOT NULL
GROUP BY Genre
order by total_gross_income desc;

# avg gross income in mupltiple languages vs avg gross income with release in single laguage

SELECT ROUND(AVG(CASE WHEN languages LIKE '%,%' THEN CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2)) END), 2) AS avg_gross_multiple_languages,
ROUND(AVG(CASE WHEN languages NOT LIKE '%,%' THEN CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2)) END), 2) AS avg_gross_single_language
FROM Movie
WHERE worlwide_gross_income IS NOT NULL;


-- select country, avg_world_wide_income, dense_rank () over(partition by country order by avg_world_wide_income) as rank_ from
-- (SELECT country, ROUND(AVG(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))), 2) AS avg_world_wide_income
-- FROM movie
-- where country is not null
-- GROUP BY country
-- HAVING avg_world_wide_income IS NOT NULL
-- ORDER BY avg_world_wide_income desc) as subquery
-- order by avg_world_wide_income desc;

# Dominant Language wise Gross Income

SELECT SUBSTRING_INDEX(languages, ',', 1) AS language, round(avg(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))),2) AS total_gross_income
FROM Movie
WHERE worlwide_gross_income IS NOT NULL
GROUP BY language
order by total_gross_income desc;

# duration wise Avg gross income and sum gross income

SELECT CASE
WHEN duration <= 60 THEN 'Less than or equal to 60 minutes'
WHEN duration <= 90 THEN 'Between 61 and 90 minutes'
WHEN duration <= 120 THEN 'Between 91 and 120 minutes'
WHEN duration <= 150 THEN 'Between 121 and 150 minutes'
WHEN duration <= 180 THEN 'Between 151 and 180 minutes'
ELSE 'More than 180 minutes'
END AS duration_bucket,
round(avg(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))),2) AS Avg_total_gross_income,
round(sum(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))),2) as sum_total_gross_income
FROM Movie
WHERE worlwide_gross_income IS NOT NULL
GROUP BY duration_bucket
order by avg_total_gross_income desc, sum_total_gross_income desc ;

# production company wise gross income

select production_company, ROUND(AVG(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))), 2) as worlwide_gross_income from movie
group by production_company
having worlwide_gross_income is not null
order by worlwide_gross_income desc;

# gross Income of movies relased in mutiple countries vs individual countries

SELECT
CASE
WHEN TRIM(country) LIKE '%,%' THEN 'Multiple Countries'
ELSE TRIM(country)
END AS release_type,
round(avg(CONVERT(REPLACE(worlwide_gross_income, '$', ''), DECIMAL(10, 2))),2) AS total_gross_income
FROM Movie
WHERE worlwide_gross_income IS NOT NULL and country is not null
GROUP BY release_type
order by total_gross_income desc;



# Areas of focus for Bollywood when producing movies for global market

# Genre
-- 1. Focus can be on Adventure, Sci-fi, Fantasy and Action in the same Order if there is sufficient Budget for the Movie
-- 2. When the Budget is limited then the focus can be on Drama, Comedy and Thriller as these are the genres with highest numbers of movies produced

# Languages
-- 1. The Movies with release in one language only seems to be performing better compared to movies release in mutiple languges. 
-- so the focus should be on releasing in single language unless the other language market is big
-- 2. The total revenue generated by the movies with dominant languages as Mandarin seems to be higher followed by cantonese and English 
-- So the movies produced must be focussed with English and Mandarin languages in mind. And other languages can be varying based on movie type

# Duration
-- Bollywood movies(Hindi) average movie duration is 125.79 where as globally movies with average duration between 121 to 150 is grossing more income.
-- so bollywood should focus on producing movies in this range. 
-- But to note more movies are produced in the range of 91 to 120 as sum_total_gross_Income is higher than other duration buckets
--  So it should be decided based on the Target Audience

# Production Houses
-- 1. Movie productions can be done by collabrating with top grossing production companies like Alibaba Pictures, Tianjin Chengzi Yingxiang Media Skydance Media and others

# Release country
-- Movie releases in China has avg_total_gross_income considerably higher than other countries followed by USA. 
-- so movie releases should be focussed more in China and USA and productions should be done keeping these target audiences in mind







