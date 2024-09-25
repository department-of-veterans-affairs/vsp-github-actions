const { formatInTimeZone } = require('date-fns-tz');
const core = require('@actions/core');

// Git list of holidays
const holidaysInput = core.getInput('holidays');
const holidays = holidaysInput.split(',').map(date => date.trim());

// Get the current date and time in EST Timezone  (YYYY-MM-DD)
const today = new Date(); // This is in UTC
const timeZone = 'America/New_York';
const formattedDate = formatInTimeZone(today, timeZone, 'yyyy-MM-dd');
const formattedTime = formatInTimeZone(today, timeZone, 'yyyy-MM-dd HH:mm:ss');

const isHoliday = holidays.includes(formattedDate);

// Output the result
core.setOutput('is_holiday', isHoliday.toString());

if (isHoliday) {
  console.log(`Today (${formattedTime}, ${timeZone}) is a holiday.`);
} else {
  console.log(`Today (${formattedTime},  ${timeZone} is not a holiday.`);
}