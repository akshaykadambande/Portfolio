
CREATE DATABASE attrition_data;
USE attrition_data;

-- ==============================================
SELECT * FROM attrition;
-- ==============================================

-- Q1. What is the overall attrition rate?
SELECT  COUNT(*) AS total_employees,
		SUM(Attrition = 'Yes') AS employees_left,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition;


-- Q2. Which departments lose the most people and the highest share?
SELECT  Department,
		COUNT(*) AS headcount,
		SUM(Attrition = 'Yes') AS employees_left,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY Department
ORDER BY attrition_rate_pct DESC;


-- Q3. Which education fields have above-average attrition?
WITH company_avg AS (
    SELECT AVG(Attrition = 'Yes') AS avg_rate
    FROM attrition
)
SELECT  EducationField,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY EducationField
HAVING AVG(Attrition = 'Yes') >
       (SELECT avg_rate FROM company_avg)
ORDER BY attrition_rate_pct DESC;


-- Q4. At what point in their tenure do employees leave?
SELECT CASE WHEN YearsAtCompany <= 1 THEN '0-1 years'
			WHEN YearsAtCompany <= 3 THEN '2-3 years'
			WHEN YearsAtCompany <= 5 THEN '4-5 years'
			WHEN YearsAtCompany <= 10 THEN '6-10 years'
			ELSE '10+ years'
		END AS tenure_band,
		COUNT(*) AS headcount,
		SUM(Attrition = 'Yes') AS employees_left,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY tenure_band
ORDER BY MIN(YearsAtCompany);


-- Q5. Which age groups have the highest attrition?
SELECT CASE WHEN Age < 25 THEN 'Under 25'
			WHEN Age < 35 THEN '25-34'
			WHEN Age < 45 THEN '35-44'
			WHEN Age < 55 THEN '45-54'
			ELSE '55+'
		END AS age_group,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY age_group
ORDER BY MIN(Age);


-- Q6. Does marital status relate to attrition?
SELECT  MaritalStatus,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY MaritalStatus
ORDER BY attrition_rate_pct DESC;


-- Q7. Are employees with more companies in their work history
-- more likely to leave?
SELECT CASE WHEN NumCompaniesWorked <= 1 THEN '1 company'
			WHEN NumCompaniesWorked <= 2 THEN '2 companies'
			WHEN NumCompaniesWorked <= 4 THEN '3-4 companies'
			ELSE '5+ companies'
		END AS job_history,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY job_history
ORDER BY MIN(NumCompaniesWorked);


-- Q8. Do employees who leave earn less than employees who stay?
SELECT  Department,
		ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN MonthlyIncome END), 0) AS avg_income_leavers,
		ROUND(AVG( CASE WHEN Attrition = 'No' THEN MonthlyIncome END), 0) AS avg_income_stayers,
		ROUND( AVG(CASE WHEN Attrition = 'No' THEN MonthlyIncome END) - AVG(CASE WHEN Attrition = 'Yes' THEN MonthlyIncome END),0) AS income_gap
FROM attrition
GROUP BY Department
ORDER BY income_gap DESC;


-- Q9. Which income quartile has the highest attrition?
WITH income_groups AS (
    SELECT  MonthlyIncome,
			Attrition,
			NTILE(4) OVER (ORDER BY MonthlyIncome) AS income_quartile
    FROM attrition
)
SELECT  income_quartile,
		MIN(MonthlyIncome) AS min_income,
		MAX(MonthlyIncome) AS max_income,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM income_groups
GROUP BY income_quartile
ORDER BY income_quartile;


-- Q10. How does job satisfaction relate to attrition?
SELECT  JobSatisfaction,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY JobSatisfaction
ORDER BY JobSatisfaction;


-- Q11. Which satisfaction factor separates leavers from stayers?
SELECT 'JobSatisfaction' AS factor,
		ROUND(AVG( CASE WHEN Attrition = 'Yes' THEN JobSatisfaction END), 2) AS avg_leavers,
		ROUND(AVG( CASE WHEN Attrition = 'No' THEN JobSatisfaction END ), 2) AS avg_stayers
FROM attrition

UNION ALL

SELECT 'EnvironmentSatisfaction',
		ROUND(AVG( CASE WHEN Attrition = 'Yes' THEN EnvironmentSatisfaction END), 2),
		ROUND(AVG( CASE WHEN Attrition = 'No' THEN EnvironmentSatisfaction END), 2)
FROM attrition

UNION ALL

SELECT  'WorkLifeBalance',
		ROUND(AVG( CASE WHEN Attrition = 'Yes' THEN WorkLifeBalance END), 2),
		ROUND(AVG( CASE WHEN Attrition = 'No' THEN WorkLifeBalance END), 2)
FROM attrition;


-- Q12. Does a long commute relate to attrition?
SELECT CASE
			WHEN DistFromHome <= 5 THEN '0-5'
			WHEN DistFromHome <= 10 THEN '6-10'
			WHEN DistFromHome <= 20 THEN '11-20'
			ELSE '21+'
		END AS distance_band,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS attrition_rate_pct
FROM attrition
GROUP BY distance_band
ORDER BY MIN(DistFromHome);


-- Q13. How much does attrition cost the company?
-- Assumption: replacement costs six months of salary.
SELECT Department,
	   SUM(Attrition = 'Yes') AS employees_left,
	   SUM( CASE WHEN Attrition = 'Yes'
				 THEN MonthlyIncome * 6
				 ELSE 0
			 END
		) AS est_replacement_cost
FROM attrition
GROUP BY Department
ORDER BY est_replacement_cost DESC;


-- Q14. Which current employees have the highest risk scores?
-- One point for each risk factor. Exclude employees who left.
SELECT Age,
		Department,
		MonthlyIncome,
		YearsAtCompany,
		JobSatisfaction,
		((YearsAtCompany <= 2) +
			(JobSatisfaction <= 2) +
			(EnvironmentSatisfaction <= 2) +
			(WorkLifeBalance <= 2) +
			(DistFromHome > 15) +
			(NumCompaniesWorked >= 5)
		) AS risk_score
FROM attrition
WHERE Attrition = 'No'
ORDER BY risk_score DESC, MonthlyIncome ASC
LIMIT 25;


-- Q15. Does a higher risk score correspond to higher attrition?
-- Include both leavers and stayers to validate the score.
WITH scored_employees AS (
    SELECT Attrition,
		   ((YearsAtCompany <= 2) +
				(JobSatisfaction <= 2) +
				(EnvironmentSatisfaction <= 2) +
				(WorkLifeBalance <= 2) +
				(DistFromHome > 15) +
				(NumCompaniesWorked >= 5)
			) AS risk_score
    FROM attrition
)
SELECT  risk_score,
		COUNT(*) AS headcount,
		ROUND(AVG(Attrition = 'Yes') * 100, 1) AS actual_attrition_rate_pct
FROM scored_employees
GROUP BY risk_score
ORDER BY risk_score;
