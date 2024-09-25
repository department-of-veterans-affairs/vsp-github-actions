const { formatInTimeZone } = require('date-fns-tz');
const core = require('@actions/core');

// Predefined list of holidays (format: YYYY-MM-DD)
const holidays = [
  "2024-01-15",
  "2024-05-27",
  "2024-06-19",
  "2024-07-04",
  "2024-09-02",
  "2024-11-11",
  "2024-11-28",
  "2024-11-29",
  "2024-12-23",
  "2024-12-24",
  "2024-12-25",
  "2024-12-26",
  "2024-12-27",
  "2024-12-28",
  "2024-12-29",
  "2024-12-30",
  "2024-12-31",
  "2025-01-01",
  "2024-09-25"
];
  
// Get the current date and time in EST Timezone  (YYYY-MM-DD)
const today = new Date(); // This is in UTC
const timeZone = 'America/New_York';
const formattedDate = formatInTimeZone(today, timeZone, 'yyyy-MM-dd');
const formattedTime = formatInTimeZone(today, timeZone, 'yyyy-MM-dd HH:mm:ss');

const isHoliday = holidays.includes(formattedDate);

// Output the result
core.setOutput('is_holiday', isHoliday.toString());

if (isHoliday) {
  console.log(`Today (${formattedTime}) in ${timeZone} is a holiday.`);
} else {
  console.log(`Today (${formattedTime}) in ${timeZone} is not a holiday.`);
}
