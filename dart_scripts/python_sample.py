# This code demonstrates how to run a DART workflow using Python.
# This code is used for documentation purposes in
# https://aptrust.github.io/dart-docs/users/scripting/
#
# --------------------------------------------------------------------------

import json
import sys
from subprocess import Popen, PIPE

class Job:

    # Be sure to set this appropriately for your system.
    # The command 'npm start' is for DART development use only.
    dart_command = 'npm start'

    def __init__(self, workflow_name, package_name):
        self.workflow_name = workflow_name
        self.package_name = package_name
        self.files = []
        self.tags = []

    def add_file(self, path):
        self.files.append(path)

    def add_tag(self, tag_file, tag_name, value):
        self.tags.append({
            "tagFile": tag_file,
            "tagName": tag_name,
            "userValue": value
        })

    def to_json(self):
        _dict = {
            "workflowName": self.workflow_name,
            "packageName": self.package_name,
            "files": self.files,
            "tags": self.tags
        }
        return json.dumps(_dict)

    def run(self):
        json_string = self.to_json()
        print(json_string)
        print("Starting job")
        cmd = "%s -- --stdin" % Job.dart_command
        child = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE, close_fds=True)
        #child.stdin.write(json_string + "\n")
        #print(child.stdout.read())
        stdout_data, stderr_data = child.communicate(json_string + "\n")
        if stdout_data is not None:
            print(stdout_data)
        if stderr_data is not None:
            sys.stderr.write(stderr_data)
        return child.returncode


# Create a new job using the "DART Test Workflow."
# This job will create a tarred bag called test.edu.my_files.tar
# in your DART bagging directory.

job = Job("DART Test Workflow", "test.edu.my_files.tar")

# Add two directories to the list of items that should go into
# the bag's payload. Note that you can add a mix of files and
# directories.

job.add_file("/Users/apd4n/aptrust/dart-docs/site")
job.add_file("/Users/apd4n/tmp/logs")

# "DART Test Workflow" uses a BagIt profile with a number of
# preset default values, which are fine for tags like Contact-Email,
# which doesn't change from bag to bag. Here we set bag-specific
# tag values.

job.add_tag("bag-info.txt", "Bag-Group-Identifier", "TestGroup_001")
job.add_tag("aptrust-info.txt", "Title", "Workflow Test Files")
job.add_tag("aptrust-info.txt", "Description", "Contains miscellaneous files for workflow testing.")

# Run the job and check the exit code. 0 indicates success.
# Non-zero values indicate failure.
exit_code = job.run()

if exit_code == 0:
    print("Job completed")
else:
    print("Job failed. Check the DART log for details.")
