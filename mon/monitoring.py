import psutil
import json

def collect(pids):
    processes = {}
    for pid in pids:
        try:
            process = psutil.Process(int(pid))

            processes[pid] = {
                "cpu": {
                    'user': process.cpu_times()[0],
                    'system': process.cpu_times()[1],
                    'percent': process.cpu_percent(),
                },
                "memory": dict(map(lambda i: (i[0], i[1] / (1024 * 1024)), process.memory_info_ex()._asdict().items()))
            }
        except:
            pass

    return json.dumps(processes)
