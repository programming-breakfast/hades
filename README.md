# Hades

To start your new Phoenix application:

1. Install dependencies with `mix deps.get`
2. Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# TODO

- [x] start, stop, restart process
- [x] start hades when processes already exists
- [x] stop process with sigterm, then with sigkill after timeout
- [x] resource monitoring of existed processes
- [x] monitoring of processes
- [x] simple web front

- [ ] get created datetime of os processes
- [ ] read soul config
- [ ] do not do cycle restarts(100, 1000, 10000)
- [ ] unmonitor processes
- [ ] web api to restart all
- [ ] resourses monitoring + restart (red zone)
- [ ] kill command


- [ ] system metrics
