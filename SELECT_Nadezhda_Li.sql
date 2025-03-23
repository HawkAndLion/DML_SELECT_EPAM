----------------------------------------------------------------------------------------------------
--Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?
----------------------------------------------------------------------------------------------------
-- VERSION 1
SELECT 
    staff.store_id,
    staff.staff_id,
    CONCAT(staff.first_name, ' ', staff.last_name) AS staff_name,
    SUM(pay.amount) AS highest_revenue
FROM staff staff
JOIN payment pay ON staff.staff_id = pay.staff_id
WHERE pay.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY staff.store_id, staff.staff_id, staff.first_name, staff.last_name
HAVING SUM(pay.amount) = (
    SELECT MAX(total_revenue)
    FROM (
        SELECT 
            store_id,
            SUM(pay.amount) AS total_revenue
        FROM staff staff
        JOIN payment pay ON staff.staff_id = pay.staff_id
        WHERE pay.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
        GROUP BY store_id, staff.staff_id
    ) AS max_revenue
    WHERE max_revenue.store_id = staff.store_id
)
ORDER BY staff.store_id;


--VERSION 2
WITH StaffRevenue AS (
    SELECT 
        staff.store_id,
        staff.staff_id,
        CONCAT(staff.first_name, ' ', staff.last_name) AS staff_name,
        SUM(pay.amount) AS highest_revenue
    FROM staff staff
    JOIN payment pay ON staff.staff_id = pay.staff_id
    WHERE pay.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY staff.store_id, staff.staff_id, staff.first_name, staff.last_name
),
MaxRevenue AS (
    SELECT 
        store_id,
        MAX(highest_revenue) AS max_revenue
    FROM StaffRevenue
    GROUP BY store_id
)
SELECT 
    sr.store_id,
    sr.staff_id,
    sr.staff_name,
    sr.highest_revenue
FROM StaffRevenue sr
INNER JOIN MaxRevenue mr
    ON sr.store_id = mr.store_id
    AND sr.highest_revenue = mr.max_revenue
ORDER BY sr.store_id;


----------------------------------------------------------------------------------------------------
--Which five movies were rented more than the others, and what is the expected age of the audience for these movies?
----------------------------------------------------------------------------------------------------
--VERSION 1
WITH TopMovies AS (
SELECT film.film_id, film.title, film.rating, COUNT(rent.rental_id) AS rental_count
FROM film film
JOIN inventory inv ON film.film_id = inv.film_id
JOIN rental rent ON inv.inventory_id = rent.inventory_id
GROUP BY film.film_id, film.title, film.rating 
ORDER BY rental_count DESC
LIMIT 5
),
RatingAgeGroup AS (
 SELECT film_id,
 CASE 
    WHEN rating = 'NC-17' THEN '18+'
	WHEN rating = 'PG-13' THEN '13+'
	WHEN rating = 'G' THEN 'All ages'
	WHEN rating = 'PG' THEN '7+'
	WHEN rating = 'R' THEN '17+'
	END AS age_group
  FROM film
)

SELECT tm.film_id, tm.title, tm.rental_count, ageGroup.age_group
FROM TopMovies tm
JOIN RatingAgeGroup ageGroup ON tm.film_id = ageGroup.film_id;


-- VERSION 2
SELECT 
    film.film_id,
    film.title,
    COUNT(ren.rental_id) AS rental_count,
    CASE 
        WHEN film.rating = 'NC-17' THEN '18+'
        WHEN film.rating = 'PG-13' THEN '13+'
        WHEN film.rating = 'G' THEN 'All ages'
        WHEN film.rating = 'PG' THEN '7+'
        WHEN film.rating = 'R' THEN '17+'
    END AS age_group
FROM film film
JOIN inventory inv ON film.film_id = inv.film_id
JOIN rental ren ON inv.inventory_id = ren.inventory_id
GROUP BY film.film_id, film.title, film.rating
ORDER BY COUNT(ren.rental_id) DESC
LIMIT 5;


----------------------------------------------------------------------------------------------------
--Which actors/actresses didn't act for a longer period of time than the others?
----------------------------------------------------------------------------------------------------
--SELECT film.title, film.release_year, fa.actor_id, actor.first_name, actor.last_name FROM film film JOIN film_actor fa ON film.film_id = fa.film_id JOIN actor actor ON actor.actor_id = fa.actor_id WHERE fa.actor_id = 59 ORDER BY release_year;
--VERSION 1
SELECT actor.actor_id, actor.first_name, actor.last_name, 
      MAX(film.release_year) AS last_release_year,
      EXTRACT(YEAR FROM CURRENT_DATE) - MAX(film.release_year) AS years_since_last_acting
FROM actor actor
LEFT JOIN film_actor fa ON fa.actor_id = actor.actor_id
LEFT JOIN film film ON fa.film_id = film.film_id
GROUP BY actor.actor_id, actor.first_name, actor.last_name
ORDER BY years_since_last_acting DESC ; 

--VERSION 2
WITH ActorLastMovie AS (
    SELECT 
        fa.actor_id,
        MAX(film.release_year) AS last_movie_release_year 
    FROM film_actor fa
    JOIN film film ON fa.film_id = film.film_id
    GROUP BY fa.actor_id
),
ActorInactiveDuration AS (
    SELECT 
        actor.actor_id,
        actor.first_name,
        actor.last_name,
        lastMovie.last_movie_release_year,
        EXTRACT(YEAR FROM CURRENT_DATE) - lastMovie.last_movie_release_year AS years_inactive
    FROM actor actor
    JOIN ActorLastMovie lastMovie ON actor.actor_id = lastMovie.actor_id
)
SELECT 
    actor_id,
    first_name,
    last_name,
    last_movie_release_year,
    years_inactive
FROM ActorInactiveDuration
ORDER BY years_inactive DESC;
