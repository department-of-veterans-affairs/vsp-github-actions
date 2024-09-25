const core = require('@actions/core');

try {
  // Predefined list of holidays (format: YYYY-MM-DD)
  const holidays = [];

  // Get today's date
  const today = new Date().toISOString().split('T')[0];
  
  // Check if today is in the list of holidays
  const isHoliday = holidays.includes(today);
  
  // Output the result
  core.setOutput('is_holiday', isHoliday.toString());

  if (isHoliday) {
    console.log(`Today (${today}) is a holiday.`);
  } else {
    console.log(`Today (${today}) is not a holiday.`);
  }
} catch (error) {
  core.setFailed(`Error checking holidays: ${error.message}`);
}
