from threading import RLock

from gomssql_python.built.gomssql_python_go import (
    NewRPCSession,
    RPCConnect,
    RPCQuery,
    RPCFetchAll,
    RPCExecute,
    RPCGetRowsAffected,
    RPCClose,
)
from gomssql_python.common import handle_exception, handle_records, handle_records_json

_new_session_lock = RLock()


def _new_session(*args):
    with _new_session_lock:
        return handle_exception(NewRPCSession, args)


class RPCSession(object):
    def __init__(self, session_id, **kwargs):
        self._session_id = session_id
        self._kwargs = kwargs

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass

    def __repr__(self):
        return "{0}(session_id={1}, {2})".format(
            self.__class__.__name__,
            repr(self._session_id),
            ", ".join("{0}={1}".format(k, repr(v)) for k, v in list(self._kwargs.items())),
        )

    def connect(self):
        return handle_exception(RPCConnect, (self._session_id,), self)

    def query(self, query):
        return handle_exception(RPCQuery, (self._session_id, query), self)

    def fetchall(self, rows_id):
        return handle_records(handle_records_json(handle_exception(RPCFetchAll, (self._session_id, rows_id), self)))

    def execute(self, query):
        return handle_exception(RPCExecute, (self._session_id, query), self)

    def rowcount(self, result_id):
        return handle_exception(RPCGetRowsAffected, (self._session_id, result_id), self)

    def close(self):
        return handle_exception(RPCClose, (self._session_id,), self)


def create_session(data_source_name):
    session_id = _new_session(
        str(data_source_name),
    )

    kwargs = {
        "data_source_name": data_source_name,
    }

    return RPCSession(session_id=session_id, **kwargs)
