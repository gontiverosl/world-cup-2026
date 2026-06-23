goals = [2, 1, 3, 0, 2, 4]

# 1. Print the first and last element by index
print(goals[0], goals[-1])

# 2. Print the middle two elements using a slice
print(goals[2:4])

# 3. Print total goals, max goals in a match, min goals in a match, and number of matches
total_goals = sum(goals)
print(total_goals)

max_goals = max(goals)
print(max_goals)

min_goals = min(goals)
print(min_goals)

matches_count = len(goals)
print(matches_count)