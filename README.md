## gomssql-python

The purpose of this module is to provide a Python interface to the Golang [gomssql-db](https://github.com/denisenkom/go-mssqldb) module.

It was made very easy with the help of the Golang [gopy](https://github.com/go-python/gopy) module.

It has come about because it seems impossible to get away from memory leaks when you're dealing with UnixODBC and FreeTDS.

#### Limitations

* Python command needs to be prefixed with GODEBUG=cgocheck=0 (or have that in the environment)

#### Prerequisites

* Go 1.13
* Python 2.7+
* pip
* virtualenvwrapper
* pkgconfig/pkg-config

#### Installation (for prod)
* ```python setup.py install``` 

#### Making a python wheel install file (for distribution)
* ```python setup.py bdist_wheel``` 

#### Setup (for dev)
Ensure pkg-config is installed

* ```mkvirtualenvwrapper -p (/path/to/pypy) gomssql-python``` 
* ```pip install -r requirements-dev.txt```
* ```./build.sh```
* ```GODEBUG=cgocheck=0 py.test -v```

#### What's worth knowing if I want to further the development?

* gopy doesn't like Go interfaces; so make sure you don't have any public (exported) interfaces
    * this includes a struct with a public property that may eventually lead to an interface

#### Example Python usage

To create an MSSQL session in Python do the following:

```
from gomssql_python import Connection

ip = "127.0.0.1"
port = 5432
database = "test"
username = "test"
password = "test"

conn_str = """
            server=%s;
            port=%i;
            database=%s;
            user id=%s;
            password=%s;
        """ % (
    ip, port, database,
    username, password
).replace('\n', '').replace(' ', '')

connection = Connection(conn_str)
cursor = connection.cursor()

query = "SELECT NOW()"

cursor.execute(query)

records = cursor.fetchall()

print("Records:")
print(records)

cursor.close()
connection.close()
```

## To develop / run the tests

    MOUNT_WORKSPACE=1 ./test.sh bash
    ./build.sh
    py.test
    
## To test the sdist package

    py.test