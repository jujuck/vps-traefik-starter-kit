psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE *.* TO '$USER_NAME'@'%';"
