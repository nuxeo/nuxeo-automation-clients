About
-----

Python client for Nuxeo Automation server

Prerequisites
-------------

This module has been tested using Python 2.7.

Usage
-------

$ python
>>> import automation_client
>>> client = automation_client.BaseAutomationClient('http://server:port/nuxeo', 'usernamme', password='*****')
>>> client.execute('Document.Query', query="Select * from Document where dc:title='INDEX.txt'")
>>> client.execute('Document.Create', op_input='doc:/default-domain/workspaces/Sandbox', type='File', name='test', properties={"dc:title":"Test"})
>>> ...
>>> exit()

