DAVKit
======

DAVKit is a Cocoa framework for communicating with WebDAV servers. It supports downloading, uploading, copying, moving, and deleting files and folders, all completely asynchronously. By subclassing `DAVRequest`, you can extend the existing support for WebDAV requests to suit your own needs. Unit test are also included for all of the supported requests. If DAVKit is missing something, or you would like to submit a patch, please file an issue in the issue tracker.

Basic Usage
-----------

To get started, include the DAVKit framework in your Mac OS X application target per usual. To use DAVKit on iPhone, copy the contents of the Sources directory into your own project.

All of the WebDAV requests are sent using the `DAVSession` class. Initialize `DAVSession` like so:

	DAVCredentials *creds = [DAVCredentials credentialsWithUsername:@"USER"
														   password:@"PASS"];
	
	NSString *root = @"http://idisk.me.com/matt.rajca"; // don't include the trailing / (slash)
	
	DAVSession *session = [[DAVSession alloc] initWithRootURL:root
												  credentials:creds];


`DAVSession` itself acts like a queue, limiting the number of requests it can make at any single time. The default is `2`. To enqueue a new WebDAV request, instantiate one of the subclasses of `DAVRequest`, and pass it to `DAVSession` as shown below:

	[session enqueueRequest:subclassOfDAVRequest];

To receive callbacks when the state of the request changes, register yourself as the delegate of the instance of `DAVRequest` before enqueueing it.


Unit Tests
----------

Before running the `Tests` target, fill in your WebDAV test server's information into the `HOST`, `USERNAME`, and `PASSWORD` #defines in `DAVTest.h`. The tests currently don't work offline.

Credits
-------

Thanks to Peter Hosey for the ISO8601DateFormatter class!

License
-------

Copyright (c) 2010 Matt Rajca

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
