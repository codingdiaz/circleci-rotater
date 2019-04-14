# CircleCI Rotator

## What is This?

This project is code (golang/terraform) that rotates AWS Keys for an IAM user on a CircleCI as environment variables.
The code that does the rotation is writen in golang and the easy way to deploy it is as a terraform module. 

## Why

CircleCI is a really cool CI\CD tool but, it hasn't solved this use case. AWS Keys should be rotated and this project makes that happen with little overhead. 