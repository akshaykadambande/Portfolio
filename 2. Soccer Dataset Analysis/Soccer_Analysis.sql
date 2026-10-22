CREATE DATABASE IF NOT EXISTS soccer;
USE soccer;

CREATE TABLE matches (
    Round            VARCHAR(20),
    Date             DATE,
    Time             TIME,
    Team             VARCHAR(50),
    Team_Score       float ,
    Opponent_Score   float ,
    Opponent         VARCHAR(50),
    Team_Points      float ,
    Opponent_Points  float ,
    season           INT,
    Location         VARCHAR(10),
    Country          VARCHAR(50),
    Competition      VARCHAR(50)
); 

SELECT * FROM matches;

-- =========================================================
-- Q01. What is the overall size and coverage of the dataset?
-- =========================================================
SELECT COUNT(*) AS total_team_match_records,
       COUNT(DISTINCT Team) AS unique_teams,
       COUNT(DISTINCT Country) AS countries,
       COUNT(DISTINCT Competition) AS competitions,
       MIN(season) AS first_season,
       MAX(season) AS last_season
FROM matches;


-- =========================================================
-- Q02. Which countries and competitions contribute the most records?
-- =========================================================
SELECT Country,
       Competition,
       COUNT(*) AS team_match_records
FROM matches
GROUP BY Country, Competition
ORDER BY team_match_records DESC;


-- =========================================================
-- Q03. What is each team's overall win, draw, and loss count?
-- =========================================================
SELECT Team,
       COUNT(*) AS matches_played,
       SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) AS wins,
       SUM(CASE WHEN Team_Score = Opponent_Score THEN 1 ELSE 0 END) AS draws,
       SUM(CASE WHEN Team_Score < Opponent_Score THEN 1 ELSE 0 END) AS losses,
       ROUND(100.0 * SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS win_rate_pct
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Team
HAVING COUNT(*) >= 20
ORDER BY win_rate_pct DESC, matches_played DESC;

-- =========================================================
-- Q05. How does home performance compare with away performance?
-- =========================================================
SELECT Location, COUNT(*) AS matches,
       SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) AS wins,
       SUM(CASE WHEN Team_Score = Opponent_Score THEN 1 ELSE 0 END) AS draws,
       SUM(CASE WHEN Team_Score < Opponent_Score THEN 1 ELSE 0 END) AS losses,
       ROUND(AVG(Team_Score), 2) AS avg_goals_scored,
       ROUND(AVG(Opponent_Score), 2) AS avg_goals_conceded,
       ROUND(100.0 * SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS win_rate_pct
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Location;


-- =========================================================
-- Q06. Which teams perform best at home compared with away?
-- =========================================================
SELECT Team, Location,
       COUNT(*) AS matches_played,
       SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) AS wins,
       ROUND(100.0 * SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS win_rate_pct,
       ROUND(AVG(Team_Score), 2) AS avg_goals_scored
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Team, Location
HAVING COUNT(*) >= 10
ORDER BY Team, win_rate_pct DESC;


-- =========================================================
-- Q07. Which teams earned the most total points?
-- =========================================================
SELECT Team,
       SUM(Team_Points) AS total_points,
       COUNT(*) AS matches_played,
       ROUND(AVG(Team_Points), 2) AS avg_points_per_match
FROM matches
WHERE Team_Points IS NOT NULL
GROUP BY Team
HAVING COUNT(*) >= 20
ORDER BY total_points DESC, avg_points_per_match DESC;

-- =========================================================
-- Q08. Who are the top 10 teams in each competition and season by points?
-- =========================================================
WITH team_season AS (
    SELECT Country, Competition, season, Team,
           COUNT(*) AS matches_played,
           SUM(Team_Points) AS points,
           SUM(Team_Score) AS goals_for,
           SUM(Opponent_Score) AS goals_against
    FROM matches
    WHERE Team_Points IS NOT NULL
    GROUP BY Country, Competition, season, Team
),
ranked AS (
    SELECT team_season.*,
           DENSE_RANK() OVER (PARTITION BY Country, Competition, season ORDER BY points DESC, goals_for - goals_against DESC, goals_for DESC) AS team_rank
    FROM team_season
)
SELECT Country, Competition, season, team_rank, Team, matches_played, points, goals_for, goals_against, goals_for - goals_against AS goal_difference
FROM ranked
WHERE team_rank <= 10
ORDER BY Country, Competition, season, team_rank;


-- =========================================================
-- Q09. Which teams have the most clean sheets?
-- =========================================================
SELECT Team, COUNT(*) AS matches_played, 
       SUM(CASE WHEN Opponent_Score = 0 THEN 1 ELSE 0 END) AS clean_sheets,
       ROUND(100.0 * SUM(CASE WHEN Opponent_Score = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS clean_sheet_rate_pct
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Team
HAVING COUNT(*) >= 20
ORDER BY clean_sheets DESC, clean_sheet_rate_pct DESC;


-- =========================================================
-- Q10. Which matches had the highest combined goals?
-- =========================================================
SELECT Date, season, Country, Competition, Team AS home_team,
       Opponent AS away_team, Team_Score AS home_team_score,
       Opponent_Score AS away_team_score,
       Team_Score + Opponent_Score AS total_goals
FROM matches
WHERE Location = 'Home' AND Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
ORDER BY total_goals DESC, Date DESC
LIMIT 20;

-- =========================================================
-- Q11. What are the biggest winning margins?
-- =========================================================
SELECT Date, season, Country, Competition, Team AS home_team,
    Opponent AS away_team, Team_Score AS home_score,
    Opponent_Score AS away_score,
    ABS(Team_Score - Opponent_Score) AS winning_margin,
    CASE
        WHEN Team_Score > Opponent_Score THEN Team
        WHEN Opponent_Score > Team_Score THEN Opponent
        ELSE 'Draw'
    END AS result_winner
FROM matches
WHERE Location = 'Home' AND Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL AND Team_Score <> Opponent_Score
ORDER BY winning_margin DESC, Date DESC
LIMIT 20;


-- =========================================================
-- Q12. Which teams draw most often?
-- =========================================================
SELECT Team, COUNT(*) AS matches_played,
       SUM(CASE WHEN Team_Score = Opponent_Score THEN 1 ELSE 0 END) AS draws,
       ROUND(100.0 * SUM(CASE WHEN Team_Score = Opponent_Score THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS draw_rate_pct
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Team
HAVING COUNT(*) >= 20
ORDER BY draw_rate_pct DESC, draws DESC;


-- =========================================================
-- Q13. How have goals and points changed year by year?
-- =========================================================
SELECT season, COUNT(*) AS team_match_records, 
       COUNT(DISTINCT Team) AS teams_in_dataset,
       ROUND(AVG(Team_Score), 2) AS avg_goals_scored_per_team_match,
       ROUND(AVG(Opponent_Score), 2) AS avg_goals_conceded_per_team_match,
       ROUND(AVG(Team_Points), 2) AS avg_points_per_team_match
FROM matches
WHERE Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY season
ORDER BY season;


-- =========================================================
-- Q14. Which teams improved or declined in points versus the prior season?
-- =========================================================
WITH season_points AS (
    SELECT
        Country,
        Competition,
        season,
        Team,
        SUM(Team_Points) AS total_points
    FROM matches
    WHERE Team_Points IS NOT NULL
    GROUP BY Country, Competition, season, Team
),
with_previous AS (
    SELECT
        season_points.*,
        LAG(total_points) OVER (
            PARTITION BY Country, Competition, Team
            ORDER BY season
        ) AS previous_available_season_points
    FROM season_points
)
SELECT
    Country,
    Competition,
    Team,
    season,
    total_points,
    previous_available_season_points,
    total_points - previous_available_season_points AS points_change
FROM with_previous
WHERE previous_available_season_points IS NOT NULL
ORDER BY points_change DESC;


-- =========================================================
-- Q15. What is each team's most frequent opponent?
-- =========================================================
WITH opponent_counts AS (
    SELECT Team, Opponent,
        COUNT(*) AS meetings,
        DENSE_RANK() OVER (PARTITION BY Team ORDER BY COUNT(*) DESC) AS opponent_rank
    FROM matches
    WHERE Team IS NOT NULL AND Opponent IS NOT NULL
    GROUP BY Team, Opponent
)
SELECT Team, Opponent, meetings
FROM opponent_counts
WHERE opponent_rank = 1
ORDER BY Team;


-- =========================================================
-- Q16. What is the head-to-head record between two chosen teams?
-- =========================================================
SELECT Team, Opponent, COUNT(*) AS meetings,
       SUM(CASE WHEN Team_Score > Opponent_Score THEN 1 ELSE 0 END) AS team_wins,
       SUM(CASE WHEN Team_Score = Opponent_Score THEN 1 ELSE 0 END) AS draws,
       SUM(CASE WHEN Team_Score < Opponent_Score THEN 1 ELSE 0 END) AS team_losses,
       SUM(Team_Score) AS goals_scored,
       SUM(Opponent_Score) AS goals_conceded
FROM matches
WHERE Team = 'REAL MADRID' AND Opponent = 'BARCELONA' AND Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Team, Opponent;



-- =========================================================
-- Q17. Which teams score in at least 80% of their matches?
-- =========================================================
SELECT Team, COUNT(*) AS matches_played,
       SUM(CASE WHEN Team_Score > 0 THEN 1 ELSE 0 END) AS matches_scored_in,
       ROUND(100.0 * SUM(CASE WHEN Team_Score > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS scoring_match_rate_pct
FROM matches
WHERE Team_Score IS NOT NULL
GROUP BY Team
HAVING COUNT(*) >= 20 AND 1.0 * SUM(CASE WHEN Team_Score > 0 THEN 1 ELSE 0 END) / COUNT(*) >= 0.80
ORDER BY scoring_match_rate_pct DESC, matches_played DESC;


-- =========================================================
-- Q18. Which competitions have the highest average goals per fixture?
-- =========================================================
SELECT Country, Competition, COUNT(*) AS fixtures,
    ROUND(AVG(Team_Score + Opponent_Score), 2) AS avg_total_goals,
    ROUND(AVG(Team_Score), 2) AS avg_home_goals,
    ROUND(AVG(Opponent_Score), 2) AS avg_away_goals
FROM matches
WHERE Location = 'Home' AND Team_Score IS NOT NULL AND Opponent_Score IS NOT NULL
GROUP BY Country, Competition
HAVING COUNT(*) >= 100
ORDER BY avg_total_goals DESC;
