"""SQLZOO: Guest House Solutions"""


"""EASY QUESTIONS"""

"1. Guest 1183. Give the booking_date and the number of nights for guest 1183."
SELECT booking_date, nights FROM booking
WHERE guest_id = 1183

"2. When do they get here? List the arrival time and the first and last names for
all guests due to arrive on 2016-11-05, order the output by time of arrival."
SELECT arrival_time, first_name, last_name FROM booking
JOIN guest ON (guest.id=booking.guest_id)
WHERE YEAR(booking_date) = 2016
   AND MONTH(booking_date) = 11
   AND DAY(booking_date) = 5
ORDER BY arrival_time

"3. Look up daily rates. Give the daily rate that should be paid for bookings with ids
5152, 5165, 5154 and 5295. Include booking id, room type, number of occupants and the amount."
SELECT booking_id, room_type_requested, occupants, amount FROM booking
JOIN rate ON (booking.occupants = rate.occupancy AND booking.room_type_requested=rate.room_type)
WHERE booking_id IN (5152, 5165, 5154, 5295)

"4. Who’s in 101? Find who is staying in room 101 on 2016-12-03, include first name, last name and address."
SELECT first_name, last_name, address FROM booking
JOIN guest ON (booking.guest_id=guest.id)
WHERE room_no = 101
   AND YEAR(booking_date) = 2016
   AND MONTH(booking_date) = 12
   AND DAY(booking_date) = 3

"5. How many bookings, how many nights? For guests 1185 and 1270 show the number of
bookings made and the total number of nights. Your output should include the guest id
and the total number of bookings and the total number of nights."
SELECT guest_id, COUNT(nights), SUM(nights) FROM booking
WHERE guest_id IN (1185, 1270)
GROUP BY guest_id



"""MEDIUM QUESTIONS"""

"6. Ruth Cadbury. Show the total amount payable by guest Ruth Cadbury for her room bookings.
You should JOIN to the rate table using room_type_requested and occupants."
SELECT SUM(nights*amount) FROM booking
JOIN guest ON (guest.id=booking.guest_id)
JOIN rate ON (rate.room_type=booking.room_type_requested AND rate.occupancy=booking.occupants)
WHERE first_name='Ruth' AND last_name='Cadbury'

"7. Including Extras. Calculate the total bill for booking 5346 including extras."
SELECT SUM(amount) FROM
  (SELECT booking_id, amount FROM booking
  JOIN rate ON (room_type=room_type_requested AND occupancy=occupants)
  WHERE booking.booking_id = 5346
  UNION
  SELECT booking.booking_id, extra.amount FROM booking
  JOIN extra ON (booking.booking_id=extra.booking_id)
  WHERE booking.booking_id = 5346) AS x
GROUP BY booking_id

"8. Edinburgh Residents. For every guest who has the word “Edinburgh” in their address show the total
number of nights booked. Be sure to include 0 for those guests who have never had a booking.
Show last name, first name, address and number of nights. Order by last name then first name."
SELECT last_name, first_name, address, SUM(CASE WHEN nights IS NULL THEN 0 ELSE nights END) AS nights FROM guest
LEFT JOIN booking ON (booking.guest_id=guest.id)
WHERE address LIKE '%Edinburgh%'
GROUP BY last_name, first_name, address

"9. How busy are we? For each day of the week beginning 2016-11-25 show the number of bookings
starting that day. Be sure to show all the days of the week in the correct order."
SELECT booking_date, COUNT(*) FROM booking
WHERE booking_date >= '2016-11-25'
GROUP BY booking_date
ORDER BY booking_date

"10. How many guests? Show the number of guests in the hotel on the night of 2016-11-21.
Include all occupants who checked in that day but not those who checked out."
SELECT SUM(occupants) FROM booking
WHERE booking_date <= '2016-11-21' AND '2016-11-21' < DATE(booking_date + nights)



"""HARD QUESTIONS"""

"11. Coincidence. Have two guests with the same surname ever stayed in the hotel on the evening?
Show the last name and both first names. Do not include duplicates."
SELECT DISTINCT a.last_name, a.first_name, b.first_name
FROM (SELECT * FROM booking
			JOIN guest ON (booking.guest_id = guest.id)) AS a
JOIN (SELECT * FROM booking
      JOIN guest ON (booking.guest_id = guest.id)) AS b
  ON a.last_name = b.last_name AND a.booking_date <= b.booking_date
	AND DATE_ADD(a.booking_date, INTERVAL a.nights DAY) > b.booking_date
	AND a.first_name > b.first_name
ORDER BY a.last_name

"12. Check out per floor. The first digit of the room number indicates the floor
– e.g. room 201 is on the 2nd floor. For each day of the week beginning 2016-11-14 show how
many rooms are being vacated that day by floor number. Show all days in the correct order."
SELECT checkout_date, SUM(CASE WHEN 1st = 1 THEN 1 ELSE 0 END) AS 1st,
  SUM(CASE WHEN 2nd = 2 THEN 1 ELSE 0 END) AS 2nd,
  SUM(CASE WHEN 3rd = 3 THEN 1 ELSE 0 END) AS 3rd
FROM (SELECT checkout_date, LEFT(room_no, 1) AS 1st, LEFT(room_no, 1) AS 2nd, LEFT(room_no, 1) AS 3rd
      FROM (SELECT *, DATE(booking_date + nights) AS checkout_date FROM booking) AS a) AS b
WHERE checkout_date >= '2016-11-14' AND checkout_date is not null
GROUP BY checkout_date


"13. Free rooms? List the rooms that are free on the day 25th Nov 2016."
SELECT id FROM room
LEFT JOIN booking ON (booking.room_no=room.id)
  AND '2016-11-25' < booking_date + INTERVAL nights DAY
  AND '2016-11-25' >= booking_date
WHERE room_no IS NULL

"14. Gross income by week. Money is collected from guests when they leave. For each Thursday in November
and December 2016, show the total amount of money collected from the previous Friday to that day, inclusive."
SELECT DATE_ADD(MAKEDATE(2016, 7), INTERVAL WEEK(DATE_ADD(booking.booking_date, INTERVAL booking.nights - 5 DAY), 0) WEEK) AS Thursday,
	SUM(booking.nights * rate.amount) + SUM(e.amount) AS weekly_income
FROM booking
JOIN rate ON (booking.occupants=rate.occupancy AND (booking.room_type_requested=rate.room_type))
LEFT JOIN (SELECT booking_id, SUM(amount) as amount
           FROM extra GROUP BY booking_id) AS e
ON (e.booking_id = booking.booking_id)
GROUP BY Thursday
