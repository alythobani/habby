module Api exposing
    ( AllRemoteData
    , QueriedFrequencyStats
    , frequencyToGraphQLString
    , graphQLRequest
    , mutationAddHabit
    , mutationEditHabitGoalFrequencies
    , mutationEditHabitSuspensions
    , mutationSetHabitData
    , mutationSetHabitDayNote
    , queryAllRemoteData
    , queryPastFrequencyStats
    )

import DefaultServices.Http exposing (post)
import DefaultServices.Util as Util
import Dict
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Models.ApiError exposing (ApiError)
import Models.FrequencyStats as FrequencyStats
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.HabitDayNote as HabitDayNote
import Models.YmdDate as YmdDate


{-| Send the `query` to the graphql endpoint.
-}
graphQLRequest : String -> Decode.Decoder a -> String -> (ApiError -> b) -> (a -> b) -> Cmd b
graphQLRequest query decoder url handleError handleSuccess =
    post url decoder (Encode.object [ ( "query", Encode.string query ) ]) handleError handleSuccess


type alias AllRemoteData =
    { habits : List Habit.Habit
    , habitData : List HabitData.HabitData
    , frequencyStatsList : List FrequencyStats.FrequencyStats
    , habitDayNotes : List HabitDayNote.HabitDayNote
    }


{-| Query for all fields on all habits and habit data, plus their frequency stats.
-}
queryAllRemoteData :
    YmdDate.YmdDate
    -> String
    -> (ApiError -> b)
    -> (AllRemoteData -> b)
    -> Cmd b
queryAllRemoteData ymd =
    let
        queryString =
            """{
  habits: get_habits """
                ++ Habit.graphQLOutputString
                ++ """
  habitData: get_habit_data {
    _id
    amount
    date {
      day
      month
      year
    }
    habit_id
  }
  frequencyStatsList: get_frequency_stats(current_client_date: {year: """
                ++ String.fromInt ymd.year
                ++ ", month: "
                ++ String.fromInt ymd.month
                ++ ", day: "
                ++ String.fromInt ymd.day
                ++ """}) {
    habit_id
    total_fragments
    successful_fragments
    total_done
    current_fragment_streak
    best_fragment_streak
    current_fragment_total
    current_fragment_goal
    current_fragment_days_left
    habit_has_started
    currently_suspended
  }
  habitDayNotes: get_habit_day_notes"""
                ++ HabitDayNote.graphQLOutputString
                ++ """
}"""
    in
    graphQLRequest
        queryString
        (Decode.succeed AllRemoteData
            |> required "habits" (Decode.list Habit.decodeHabit)
            |> required "habitData" (Decode.list HabitData.decodeHabitData)
            |> required "frequencyStatsList" (Decode.list FrequencyStats.decodeFrequencyStats)
            |> required "habitDayNotes" (Decode.list HabitDayNote.decodeHabitDayNote)
            |> Decode.at [ "data" ]
        )


type alias QueriedFrequencyStats =
    { frequencyStatsList : List FrequencyStats.FrequencyStats }


{-| Query for all fields on all habits and habit data, plus their frequency stats.
-}
queryPastFrequencyStats :
    YmdDate.YmdDate
    -> List String
    -> String
    -> (ApiError -> b)
    -> (QueriedFrequencyStats -> b)
    -> Cmd b
queryPastFrequencyStats ymd habitIds =
    let
        queryString =
            "{frequencyStatsList: get_frequency_stats(current_client_date: {year: "
                ++ String.fromInt ymd.year
                ++ ", month: "
                ++ String.fromInt ymd.month
                ++ ", day: "
                ++ String.fromInt ymd.day
                ++ "}"
                ++ (if List.isEmpty habitIds then
                        ""

                    else
                        ", habit_ids: " ++ Debug.toString habitIds
                   )
                ++ """) {
    habit_id
    total_fragments
    successful_fragments
    total_done
    current_fragment_streak
    best_fragment_streak
    current_fragment_total
    current_fragment_goal
    current_fragment_days_left
    habit_has_started
    currently_suspended
  }
}"""
    in
    graphQLRequest
        queryString
        (Decode.succeed QueriedFrequencyStats
            |> required "frequencyStatsList" (Decode.list FrequencyStats.decodeFrequencyStats)
            |> Decode.at [ "data" ]
        )


mutationAddHabit : Habit.CreateHabit -> YmdDate.YmdDate -> String -> (ApiError -> b) -> (Habit.Habit -> b) -> Cmd b
mutationAddHabit createHabit ymd =
    let
        commonFields =
            Habit.getCommonCreateFields createHabit

        startDate =
            case commonFields.initialFrequency of
                Habit.TotalWeekFrequency _ ->
                    YmdDate.getFirstMondayAfterDate ymd

                _ ->
                    ymd

        templateDict =
            Dict.fromList
                [ ( "type_name"
                  , if isGoodHabit then
                        "good_habit"

                    else
                        "bad_habit"
                  )
                , ( "name", Util.encodeString commonFields.name )
                , ( "description", Util.encodeString commonFields.description )
                , ( "time_of_day"
                  , case createHabit of
                        Habit.CreateGoodHabit { timeOfDay } ->
                            "time_of_day: " ++ (Debug.toString timeOfDay |> String.toUpper) ++ ","

                        _ ->
                            ""
                  )
                , ( "unit_name_singular", Util.encodeString commonFields.unitNameSingular )
                , ( "unit_name_plural", Util.encodeString commonFields.unitNamePlural )
                , ( "initial_frequency_name"
                  , if isGoodHabit then
                        "initial_target_frequency"

                    else
                        "initial_threshold_frequency"
                  )
                , ( "initial_frequency_value"
                  , frequencyToGraphQLString commonFields.initialFrequency
                  )
                , ( "frequency_start_date", YmdDate.toGraphQLInputString startDate )
                , ( "habit_output", Habit.graphQLOutputString )
                ]

        isGoodHabit =
            case createHabit of
                Habit.CreateGoodHabit _ ->
                    True

                _ ->
                    False

        queryString =
            """mutation {
              add_habit(create_habit_data: {
                type_name: "{{type_name}}",
                {{type_name}}: {
                  name: {{name}},
                  description: {{description}},
                  {{time_of_day}}
                  {{initial_frequency_name}}: {{initial_frequency_value}},
                  unit_name_singular: {{unit_name_singular}},
                  unit_name_plural: {{unit_name_plural}}
                }
              }, frequency_start_date: {{frequency_start_date}}) {{habit_output}}
            }"""
                |> Util.templater templateDict
    in
    graphQLRequest queryString <| Decode.at [ "data", "add_habit" ] Habit.decodeHabit


frequencyToGraphQLString : Habit.Frequency -> String
frequencyToGraphQLString frequency =
    case frequency of
        Habit.EveryXDayFrequency { days, times } ->
            Util.templater
                (Dict.fromList [ ( "days", String.fromInt days ), ( "times", String.fromInt times ) ])
                """{
                  type_name: "every_x_days_frequency",
                  every_x_days_frequency: {
                      days: {{days}},
                      times: {{times}}
                  }
                  }"""

        Habit.TotalWeekFrequency times ->
            Util.templater
                (Dict.fromList [ ( "times", String.fromInt times ) ])
                """{
                  type_name: "total_week_frequency",
                  total_week_frequency: {
                      week: {{times}}
                  }
                  }"""

        Habit.SpecificDayOfWeekFrequency { monday, tuesday, wednesday, thursday, friday, saturday, sunday } ->
            Util.templater
                (Dict.fromList
                    [ ( "monday", String.fromInt monday )
                    , ( "tuesday", String.fromInt tuesday )
                    , ( "wednesday", String.fromInt wednesday )
                    , ( "thursday", String.fromInt thursday )
                    , ( "friday", String.fromInt friday )
                    , ( "saturday", String.fromInt saturday )
                    , ( "sunday", String.fromInt sunday )
                    ]
                )
                """{
                  type_name: "specific_day_of_week_frequency",
                  specific_day_of_week_frequency: {
                  monday: {{monday}},
                  tuesday: {{tuesday}},
                  wednesday: {{wednesday}},
                  thursday: {{thursday}},
                  friday: {{friday}},
                  saturday: {{saturday}},
                  sunday: {{sunday}}
                  }
                  }"""


mutationEditHabitGoalFrequencies : String -> List Habit.FrequencyChangeRecord -> String -> String -> (ApiError -> b) -> (Habit.Habit -> b) -> Cmd b
mutationEditHabitGoalFrequencies habitId newFrequencies habitType =
    let
        frequencyChangeRecordToGraphQLString : Habit.FrequencyChangeRecord -> String
        frequencyChangeRecordToGraphQLString fcr =
            let
                fcrTemplateDict =
                    Dict.fromList
                        [ ( "start_date_day", String.fromInt fcr.startDate.day )
                        , ( "start_date_month", String.fromInt fcr.startDate.month )
                        , ( "start_date_year", String.fromInt fcr.startDate.year )
                        , ( "end_date"
                          , case fcr.endDate of
                                Just { day, month, year } ->
                                    Util.templater
                                        (Dict.fromList
                                            [ ( "day", String.fromInt day )
                                            , ( "month", String.fromInt month )
                                            , ( "year", String.fromInt year )
                                            ]
                                        )
                                        """{
                          day: {{day}},
                          month: {{month}},
                          year: {{year}}
                          }"""

                                Nothing ->
                                    "null"
                          )
                        , ( "new_frequency"
                          , frequencyToGraphQLString fcr.newFrequency
                          )
                        ]
            in
            """{
          start_date: {
            day: {{start_date_day}},
            month: {{start_date_month}},
            year: {{start_date_year}}
          },
          end_date: {{end_date}},
          new_frequency: {{new_frequency}}
          }"""
                |> Util.templater fcrTemplateDict

        templateDict =
            Dict.fromList
                [ ( "habit_type"
                  , if isGoodHabit then
                        "good_habit"

                    else
                        "bad_habit"
                  )
                , ( "habit_id", Util.encodeString habitId )
                , ( "new_frequencies"
                  , newFrequencies
                        |> List.map frequencyChangeRecordToGraphQLString
                        |> String.join ", "
                  )
                , ( "habit_output", Habit.graphQLOutputString )
                ]

        isGoodHabit =
            case habitType of
                "good_habit" ->
                    True

                _ ->
                    False

        queryString =
            """mutation {
            edit_habit_goal_frequencies(
              habit_id: {{habit_id}},
              habit_type: "{{habit_type}}",
              new_frequencies: [{{new_frequencies}}]
            ) {{habit_output}}
            }"""
                |> Util.templater templateDict
    in
    graphQLRequest queryString <| Decode.at [ "data", "edit_habit_goal_frequencies" ] Habit.decodeHabit


mutationSetHabitData : YmdDate.YmdDate -> String -> Int -> String -> (ApiError -> b) -> (HabitData.HabitData -> b) -> Cmd b
mutationSetHabitData { day, month, year } habitId amount =
    let
        templateDict =
            Dict.fromList <|
                [ ( "day", String.fromInt day )
                , ( "month", String.fromInt month )
                , ( "year", String.fromInt year )
                , ( "amount", String.fromInt amount )
                , ( "habit_id", habitId )
                ]

        query =
            """mutation {
\tset_habit_data(date: { day: {{day}}, month: {{month}}, year: {{year}}}, amount: {{amount}}, habit_id: "{{habit_id}}") {
\t\t_id,
\t\tamount,
\t\tdate {
\t\t\tyear,
\t\t\tmonth,
\t\t\tday
\t\t},
\t\thabit_id
\t}
}"""
                |> Util.templater templateDict
    in
    graphQLRequest query (Decode.at [ "data", "set_habit_data" ] HabitData.decodeHabitData)


mutationSetHabitDayNote : YmdDate.YmdDate -> String -> String -> String -> (ApiError -> b) -> (HabitDayNote.HabitDayNote -> b) -> Cmd b
mutationSetHabitDayNote ymd habitId note =
    let
        templateDict =
            Dict.fromList <|
                [ ( "date", YmdDate.toGraphQLInputString ymd )
                , ( "note", Util.encodeString note )
                , ( "habit_id", Util.encodeString habitId )
                , ( "habit_day_note_output", HabitDayNote.graphQLOutputString )
                ]

        query =
            """mutation {
              set_habit_day_note(
                date: {{date}},
                note: {{note}},
                habit_id: {{habit_id}}
              ) {{habit_day_note_output}}
            }"""
                |> Util.templater templateDict
    in
    graphQLRequest query (Decode.at [ "data", "set_habit_day_note" ] HabitDayNote.decodeHabitDayNote)


mutationEditHabitSuspensions : String -> List Habit.SuspendedInterval -> String -> (ApiError -> b) -> (Habit.Habit -> b) -> Cmd b
mutationEditHabitSuspensions habitId newSuspensions =
    let
        suspendedIntervalToGraphQLString : Habit.SuspendedInterval -> String
        suspendedIntervalToGraphQLString suspendedInterval =
            let
                suspendedIntervalTemplateDict =
                    Dict.fromList
                        [ ( "start_date", YmdDate.toGraphQLInputString suspendedInterval.startDate )
                        , ( "end_date"
                          , case suspendedInterval.endDate of
                                Just ymd ->
                                    YmdDate.toGraphQLInputString ymd

                                Nothing ->
                                    "null"
                          )
                        ]
            in
            """{
              start_date: {{start_date}},
              end_date: {{end_date}}
            }"""
                |> Util.templater suspendedIntervalTemplateDict

        templateDict =
            Dict.fromList
                [ ( "habit_id", Util.encodeString habitId )
                , ( "new_suspensions"
                  , newSuspensions
                        |> List.map suspendedIntervalToGraphQLString
                        |> String.join ", "
                  )
                , ( "habit_output", Habit.graphQLOutputString )
                ]

        queryString =
            """mutation {
            edit_habit_suspensions(
              habit_id: {{habit_id}},
              new_suspensions: [{{new_suspensions}}]
            ) {{habit_output}}
            }"""
                |> Util.templater templateDict
    in
    graphQLRequest queryString <| Decode.at [ "data", "edit_habit_suspensions" ] Habit.decodeHabit
