
<h1 align="center">Welcome to my Database-Backup-script 👋</h1>
<p>
</p>

# Script to make backup copies of a mysql / mariadb database that is hosted in a docker container.
# This script allows to ignore the databases that we do not want to save in the backup copy by adding it to the DBSKIPLIST list.

## Example:
```sh
## DBSKIPLIST="information_schema
performance_schema
mysql
sys"
```


It also has a monthly and yearly filing function.
Once the month is over. A .tar.gz file is created.
The same goes for the finished year.



The script saves the database dump in sql format, with the following structure inside a .tar.gz file.

```sh
/YEAR/MONTH/NOW_DATE/mysql/database.sql
```


## Author

👤 **Javidot** * Github: [@elj4v1](https://github.com/elj4v1)

## 📝 License

Copyright © 2021 [Javidot](https://github.com/elj4v1).<br />
This project is [MIT](https://github.com/BamButz/docker-ragemp/blob/master/LICENSE) licensed.

Based on [BamButz](https://github.com/BamButz/docker-ragemp) docker image<br />

## Show your support
***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
