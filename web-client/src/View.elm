module View exposing (..)

import DefaultServices.Infix exposing (..)
import DefaultServices.Util as Util
import Dict
import Html exposing (Html, button, div, hr, i, input, span, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Maybe.Extra as Maybe
import Model exposing (Model)
import Models.ApiError as ApiError
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.YmdDate as YmdDate
import Msg exposing (Msg(..))
import RemoteData


view : Model -> Html Msg
view model =
    div
        [ class "view" ]
        [ renderTodayPanel
            model.ymd
            model.allHabits
            model.allHabitData
            model.addHabit
            model.editingTodayHabitAmount
        ]


renderTodayPanel :
    YmdDate.YmdDate
    -> RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> Habit.AddHabitInputData
    -> Dict.Dict String Int
    -> Html Msg
renderTodayPanel ymd rdHabits rdHabitData addHabit editingHabitDataDict =
    let
        createHabitData =
            Habit.extractCreateHabit addHabit
    in
    div
        [ class "today-panel" ]
        [ div [ class "today-panel-title" ] [ text "Todays Progress" ]
        , div [ class "today-panel-date" ] [ text <| YmdDate.prettyPrint ymd ]
        , case ( rdHabits, rdHabitData ) of
            ( RemoteData.Success habits, RemoteData.Success habitData ) ->
                let
                    goodHabits =
                        List.filterMap
                            (\habit ->
                                case habit of
                                    Habit.GoodHabit goodHabitRecord ->
                                        Just goodHabitRecord

                                    _ ->
                                        Nothing
                            )
                            habits

                    badHabits =
                        List.filterMap
                            (\habit ->
                                case habit of
                                    Habit.BadHabit badHabitRecord ->
                                        Just badHabitRecord

                                    _ ->
                                        Nothing
                            )
                            habits

                    renderHabit habitRecord =
                        let
                            relevantHabitData =
                                List.filter (.habitId >> (==) habitRecord.id) habitData

                            habitDataForToday =
                                List.filter (.date >> (==) ymd) relevantHabitData
                                    |> List.head
                                    |> (\habitDatum ->
                                            case habitDatum of
                                                Nothing ->
                                                    0

                                                Just { amount } ->
                                                    amount
                                       )

                            editingHabitData =
                                Dict.get habitRecord.id editingHabitDataDict
                        in
                        div
                            [ class "habit" ]
                            [ div [ class "habit-name" ] [ text <| habitRecord.name ]
                            , div
                                [ classList
                                    [ ( "habit-amount-complete", True )
                                    , ( "editing", Maybe.isJust <| editingHabitData )
                                    ]
                                ]
                                [ input
                                    [ placeholder <|
                                        toString habitDataForToday
                                            ++ " "
                                            ++ (if habitDataForToday == 1 then
                                                    habitRecord.unitNameSingular
                                                else
                                                    habitRecord.unitNamePlural
                                               )
                                            ++ " so far today..."
                                    , onInput <| OnHabitDataInput habitRecord.id
                                    , Util.onKeydown
                                        (\key ->
                                            if key == KK.Enter then
                                                Just <| SetHabitData ymd habitRecord.id editingHabitData
                                            else
                                                Nothing
                                        )
                                    , value (editingHabitData ||> toString ?> "")
                                    ]
                                    []
                                , i
                                    [ classList [ ( "material-icons", True ) ]
                                    , onClick <| SetHabitData ymd habitRecord.id editingHabitData
                                    ]
                                    [ text "check_box" ]
                                ]
                            ]
                in
                div []
                    [ div
                        [ class "habit-list good-habits" ]
                        (List.map renderHabit goodHabits)
                    , div
                        [ class "habit-list bad-habits" ]
                        (List.map renderHabit badHabits)
                    , button
                        [ class "add-habit"
                        , onClick <|
                            if addHabit.openView then
                                OnCancelAddHabit
                            else
                                OnOpenAddHabit
                        ]
                        [ text <|
                            if addHabit.openView then
                                "Cancel"
                            else
                                "Add Habit"
                        ]
                    ]

            ( RemoteData.Failure apiError, _ ) ->
                text "Failure..."

            ( _, RemoteData.Failure apiError ) ->
                text "Failure..."

            _ ->
                text "Loading..."
        , hr [ classList [ ( "add-habit-line-breaker", True ), ( "visibility-hidden", not addHabit.openView ) ] ] []
        , div
            [ classList [ ( "add-habit-input-form", True ), ( "display-none", not addHabit.openView ) ] ]
            [ div
                [ class "add-habit-input-form-habit-tag-name" ]
                [ button
                    [ classList [ ( "selected", addHabit.kind == Habit.GoodHabitKind ) ]
                    , onClick <| OnSelectAddHabitKind Habit.GoodHabitKind
                    ]
                    [ text "Good Habit" ]
                , button
                    [ classList [ ( "selected", addHabit.kind == Habit.BadHabitKind ) ]
                    , onClick <| OnSelectAddHabitKind Habit.BadHabitKind
                    ]
                    [ text "Bad Habit" ]
                ]
            , div
                [ class "add-habit-input-form-name-and-description" ]
                [ input
                    [ class "add-habit-input-form-name"
                    , placeholder "Name..."
                    , onInput OnAddHabitNameInput
                    , value addHabit.name
                    ]
                    []
                , textarea
                    [ class "add-habit-input-form-description"
                    , placeholder "Short description..."
                    , onInput OnAddHabitDescriptionInput
                    , value addHabit.description
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-input-form-time-of-day", True )
                    , ( "display-none", addHabit.kind /= Habit.GoodHabitKind )
                    ]
                ]
                [ button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Anytime ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Anytime
                    ]
                    [ text "ANYTIME" ]
                , button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Morning ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Morning
                    ]
                    [ text "MORNING" ]
                , button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Evening ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Evening
                    ]
                    [ text "EVENING" ]
                ]
            , div
                [ class "add-habit-input-form-unit-name" ]
                [ input
                    [ class "habit-unit-name-singular"
                    , placeholder "Unit name singular..."
                    , onInput OnAddHabitUnitNameSingularInput
                    , value addHabit.unitNameSingular
                    ]
                    []
                , input
                    [ class "habit-unit-name-plural"
                    , placeholder "Unit name plural..."
                    , onInput OnAddHabitUnitNamePluralInput
                    , value addHabit.unitNamePlural
                    ]
                    []
                ]
            , div
                [ class "add-habit-input-form-frequency-tag-name" ]
                [ button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.TotalWeekFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.TotalWeekFrequencyKind
                    ]
                    [ text "X Per Week" ]
                , button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.SpecificDayOfWeekFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.SpecificDayOfWeekFrequencyKind
                    ]
                    [ text "Specific Days of Week" ]
                , button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.EveryXDayFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.EveryXDayFrequencyKind
                    ]
                    [ text "Y Per X Days" ]
                ]
            , div
                [ classList
                    [ ( "add-habit-input-form-x-times-per-week", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.TotalWeekFrequencyKind )
                    ]
                ]
                [ input
                    [ placeholder "X"
                    , onInput OnAddHabitTimesPerWeekInput
                    , value (addHabit.timesPerWeek ||> toString ?> "")
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-input-form-specific-days-of-week", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.SpecificDayOfWeekFrequencyKind )
                    ]
                ]
                [ input
                    [ placeholder "Monday"
                    , onInput OnAddHabitSpecificDayMondayInput
                    , value (addHabit.mondayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Tuesday"
                    , onInput OnAddHabitSpecificDayTuesdayInput
                    , value (addHabit.tuesdayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Wednesday"
                    , onInput OnAddHabitSpecificDayWednesdayInput
                    , value (addHabit.wednesdayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Thursday"
                    , onInput OnAddHabitSpecificDayThursdayInput
                    , value (addHabit.thursdayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Friday"
                    , onInput OnAddHabitSpecificDayFridayInput
                    , value (addHabit.fridayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Saturday"
                    , onInput OnAddHabitSpecificDaySaturdayInput
                    , value (addHabit.saturdayTimes ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Sunday"
                    , onInput OnAddHabitSpecificDaySundayInput
                    , value (addHabit.sundayTimes ||> toString ?> "")
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-input-form-x-times-per-y-days", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.EveryXDayFrequencyKind )
                    ]
                ]
                [ input
                    [ placeholder "Times"
                    , onInput OnAddHabitTimesInput
                    , value (addHabit.times ||> toString ?> "")
                    ]
                    []
                , input
                    [ placeholder "Days"
                    , onInput OnAddHabitDaysInput
                    , value (addHabit.days ||> toString ?> "")
                    ]
                    []
                ]
            , case createHabitData of
                Nothing ->
                    Util.hiddenDiv

                Just createHabitData ->
                    button
                        [ class "add-new-habit"
                        , onClick <| AddHabit createHabitData
                        ]
                        [ text "Create Habit" ]
            ]
        ]
