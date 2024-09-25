const core = require('@actions/core');

try {
  // Predefined list of holidays (format: YYYY-MM-DD)
  const holidays = [
    "2024/01/15",
    "2024/05/27",
    "2024/06/19",
    "2024/07/04",
    "2024/09/02",
    "2024/11/11",
    "2024/11/28",
    "2024/11/29",
    "2024/12/23",
    "2024/12/24",
    "2024/12/25",
    "2024/12/26",
    "2024/12/27",
    "2024/12/28",
    "2024/12/29",
    "2024/12/30",
    "2024/12/31",
    "2025/12/01"
  ];
  
  // Check if today is in the list of holidays
  const today = new Date().toISOString().split('T')[0]; // TODO: Need to get Eastern TZ
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
