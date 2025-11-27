#!/bin/bash

# Function to add or subtract hours to a given date in YYYYMMDDHH format
add_hours() {
    # Check if the correct number of arguments is provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: add_hours YYYYMMDDHH HOURS"
        return 1
    fi
    
    # Extract arguments
    input_date=$1
    hours_to_add=$2

    # Create a date string from the input
    date_string="${input_date:0:8} ${input_date:8:2}:00"

    # Convert input date to a UTC format that date command can understand
    formatted_date=$(date -u -d "$date_string" +"%Y-%m-%d %H:%M:%S")

    # Check if the date command recognized the date
    if [ $? -ne 0 ]; then
        echo "Invalid date format. Please use YYYYMMDDHH format."
        return 1
    fi

    # Add or subtract hours
    new_date=$(date -u -d "${formatted_date} ${hours_to_add} hours" +"%Y%m%d%H")

    # Output the new date and hour
    echo "$new_date"
}
