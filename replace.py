#!/usr/bin/env python

import yaml
import sys
import re
import yamlordereddictloader

if len(sys.argv) != 2:
    sys.exit(1)

with open(sys.argv[1], 'r') as ansibleFile:
    tasks = yaml.load(ansibleFile, Loader=yamlordereddictloader.Loader)
    
    for task in tasks:
        if 'include' in task.keys():

            new_include = 'include_tasks'
            if 'static' in task.keys():
                if task['static']:
                    new_include = 'import_tasks'
                del(task['static'])

            include_data = task['include']
            tokens = re.findall('[\w.]+|\".+?\"|{{.+?}}', include_data)
            filename = tokens[0]
            tokens = tokens[1:]

            task[new_include] = filename
            task['vars'] = {}
            it = iter(tokens)
            for token in it:
                task['vars'][token] = next(it)

            del(task['include'])
            task.move_to_end('vars', last=False)
            task.move_to_end(new_include, last=False)
            task.move_to_end('name', last=False)
    out = yaml.dump(tasks, Dumper=yamlordereddictloader.Dumper)
    print(out)

    # write back to original file
    #ansibleFile.seek(0)
    #ansibleFile.write(out)
    #ansibleFile.truncate()
