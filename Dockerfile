from mcr.microsoft.com/mssql/rhel/server

user root

run groupadd -g 10001 mssql && \
    usermod -a -G mssql mssql

user mssql