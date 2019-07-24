import json

class Job:
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
        return json.dumps(self.__dict__)

    def run(self):
        print('Running')
