using Project_biloumak
using GeometryBasics

antennas = [
    Antenna(Point3f(10, 10, 0), 20.0f0, 5.0f0, 0.5f0, 8.0f0),
    Antenna(Point3f(-20, 30, 0), 25.0f0, 6.0f0, 0.5f0, 10.0f0)
]

Project_biloumak.main()