# Usage

```
....
jobs:
  holiday-checker:
    runs-on: ubuntu-latest
    outputs:
      is_holiday: ${{ steps.holiday-check.outputs.is_holiday }}
    steps:
      - name: Check if today is a holiday
        id: holiday-check
        uses: department-of-veterans-affairs/vsp-github-actions/holiday-checker@main
  main-job:
    needs: holiday-checker
    if: needs.holiday-checker.outputs.is_holiday == 'false'
....
```
