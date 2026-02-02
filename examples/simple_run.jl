using Project_biloumak
using GeometryBasics

antennas = [
    Antenna(Point3f(-15.0, -15.0, 0.0), height=12.0f0, donut_radius=4.0f0, transfer_time=0.1f0),
    Antenna(Point3f(15.0, 10.0, 0.0), height=18.0f0, donut_radius=6.0f0, transfer_time=6.0f0),
    Antenna(Point3f(0.0, -20.0, 0.0), height=10.0f0, donut_radius=3.5f0, transfer_time=4.0f0),
]

start_pos = Point3f(5, 5, 10)

Project_biloumak.main(antennas=antennas, start_position=start_pos)