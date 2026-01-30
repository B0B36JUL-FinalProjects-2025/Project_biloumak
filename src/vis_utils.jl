function get_direction_angle(traj, idx)
    if idx >= length(traj)
        idx= length(traj)-1
    end
    p1 = traj[idx]
    p2 = traj[min(idx+1,length(traj))]
    dx = p2[1]-p1[1]
    dy = p2[2]-p1[2]
    return atan(dy, dx)
end