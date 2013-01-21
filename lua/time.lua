-- helpers for dealing with time

-- time internally is stored as a single number representing the hours since YW 0
-- eacy
-- each year has 12 months
-- each month has 30 days
-- so each year has 360 days
-- that's it

HOUR = 1
DAY = 24
MONTH = 30*24
YEAR = 12*30*24

function store_time(year, month, day, hour)
	return YEAR*year + MONTH*month + DAY*day + HOUR*hour
end

months_of_the_year = { _ "January", _ "February", _ "March", _ "April", _ "May", _ "June",  _ "July", _ "August", _ "September", _ "November", _ "October", _ "December" }

function get_year(hour)
	return math.floor(hour / YEAR)
end

function get_month(hour)
	return math.floor((hour % YEAR) / MONTH)
end

function get_day(hour)
	return math.floor((hour % MONTH) / DAY)
end

function get_hour(hour)
	return math.floor(hour % DAY)
end

function get_time_string(hour)
	local year = get_year(hour)
	local month = get_month(hour)
	local day = get_day(hour)
	local hour = get_hour(hour)
	
	return hour .. ":00, "..months_of_the_year[month] .. " " .. day .. ", " .. year
end