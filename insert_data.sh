#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Truncate all data
$PSQL "TRUNCATE TABLE games, teams"

# Get all unique teams for insertion to avoid unnecessary querying the database.
TEAMS_TO_INSERT=()

while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Skip header
  if [[ $YEAR == 'year' ]]
  then
    continue
  fi
  # Get winner and opponent in a single array
  TEAMS=("$WINNER" "$OPPONENT")
  for TEAM in "${TEAMS[@]}"
  do
    # Check if team already exists in external array.
    EXISTS=0
    for E in "${TEAMS_TO_INSERT[@]}"
    do
      if [[ $E == $TEAM ]]
      then
        EXISTS=1
        break
      fi
    done
    # If it doesn't, insert.
    if [[ $EXISTS == 0 ]]
    then
      TEAMS_TO_INSERT+=("$TEAM")
    fi
  done
done < games.csv

TEAMS_TO_INSERT=$(printf ",('%s')" "${TEAMS_TO_INSERT[@]}")
TEAMS_TO_INSERT=${TEAMS_TO_INSERT:1}

$PSQL "INSERT INTO teams(name) VALUES $TEAMS_TO_INSERT;"

# Get all teams ids with an associative array
declare -A TEAMS_IDS

while IFS="|" read TEAM TEAM_ID
do
  TEAMS_IDS[${TEAM}]=$TEAM_ID
done <<< $($PSQL "SELECT name, team_id FROM teams;")

# Get all games alongside their data/relations for insertion to avoid unnecessary querying the database.
GAMES_TO_INSERT=()

while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
   # Skip header
  if [[ $YEAR == 'year' ]]
  then
    continue
  fi
  WINNER_ID=${TEAMS_IDS[$WINNER]}
  OPPONENT_ID=${TEAMS_IDS[$OPPONENT]}
  GAMES_TO_INSERT+=("($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
  #echo $(printf ",('%s')" "${WINNER}")
done < games.csv

GAMES_TO_INSERT=$(printf ",%s" "${GAMES_TO_INSERT[@]}")
GAMES_TO_INSERT=${GAMES_TO_INSERT:1}

$PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) values $GAMES_TO_INSERT;"
