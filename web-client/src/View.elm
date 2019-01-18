module View exposing (dropdownIcon, habitActionsDropdownDiv, renderHabitBox, renderHistoryViewerPanel, renderSetHabitDataShortcut, renderTodayPanel, view)

import Array
import DefaultServices.Infix exposing (..)
import DefaultServices.Util as Util
import Dict
import Dropdown
import HabitUtil
import Html exposing (Html, button, div, hr, i, input, span, text, textarea)
import Html.Attributes exposing (class, classList, id, placeholder, value)
import Html.Events exposing (onClick, onInput, onMouseEnter, onMouseLeave)
import Keyboard.Extra as KK
import Material
import Material.Options as Options
import Material.Toggles as Toggles
import Maybe.Extra as Maybe
import Model exposing (Model)
import Models.ApiError as ApiError
import Models.FrequencyStats as FrequencyStats
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.YmdDate as YmdDate
import Msg exposing (Msg(..))
import RemoteData


view : Model -> Html Msg
view model =
    div
        [ classList [ ( "view", True ), ( "dark-mode", model.darkModeOn ) ]
        , Util.onKeydown
            (\key ->
                if key == KK.Space then
                    Just OnToggleShowSetHabitDataShortcut

                else
                    Nothing
            )
        ]
        [ renderTodayPanel
            model.ymd
            model.allHabits
            model.allHabitData
            model.allFrequencyStats
            model.addHabit
            model.editingTodayHabitAmount
            model.openTodayViewer
            model.todayViewerHabitActionsDropdowns
            model.darkModeOn
            model.mdl
        , renderHistoryViewerPanel
            model.openHistoryViewer
            model.historyViewerDateInput
            model.historyViewerSelectedDate
            model.allHabits
            model.allHabitData
            model.historyViewerFrequencyStats
            model.editingHistoryHabitAmount
            model.historyViewerHabitActionsDropdowns
        , renderSetHabitDataShortcut
            model.showSetHabitDataShortcut
            model.setHabitDataShortcutHabitNameFilterText
            model.setHabitDataShortcutFilteredHabits
            model.setHabitDataShortcutSelectedHabitIndex
            model.showSetHabitDataShortcutAmountForm
            model.allHabitData
            model.ymd
            model.setHabitDataShortcutInputtedAmount
        , renderEditGoalDialog
            model.showEditGoalDialog
        ]


renderTodayPanel :
    YmdDate.YmdDate
    -> RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> RemoteData.RemoteData ApiError.ApiError (List FrequencyStats.FrequencyStats)
    -> Habit.AddHabitInputData
    -> Dict.Dict String Int
    -> Bool
    -> Dict.Dict String Dropdown.State
    -> Bool
    -> Material.Model
    -> Html Msg
renderTodayPanel ymd rdHabits rdHabitData rdFrequencyStatsList addHabit editingHabitDataDict openView habitActionsDropdowns darkModeOn mdl =
    let
        createHabitData =
            Habit.extractCreateHabit addHabit
    in
    div
        [ class "today-panel" ]
        [ div [ class "today-panel-title", onClick OnToggleTodayViewer ] [ text "Today's Progress" ]
        , div [ class "dark-mode-switch" ]
            [ Toggles.switch
                Mdl
                [ 0 ]
                mdl
                [ Options.onToggle OnToggleDarkMode
                , Toggles.ripple
                , Toggles.value darkModeOn
                ]
                [ text <|
                    if darkModeOn then
                        "Dark Mode"

                    else
                        "Light Mode"
                ]
            ]
        , dropdownIcon openView NoOp
        , div [ class "today-panel-date" ] [ text <| YmdDate.prettyPrint ymd ]
        , case ( rdHabits, rdHabitData ) of
            ( RemoteData.Success habits, RemoteData.Success habitData ) ->
                let
                    ( goodHabits, badHabits ) =
                        Habit.splitHabits habits

                    ( sortedGoodHabits, sortedBadHabits, sortedSuspendedHabits ) =
                        case rdFrequencyStatsList of
                            RemoteData.Success frequencyStatsList ->
                                let
                                    ( goodActiveHabits, badActiveHabits, suspendedHabits ) =
                                        HabitUtil.splitHabitsByCurrentlySuspended frequencyStatsList goodHabits badHabits
                                in
                                ( HabitUtil.sortHabitsByCurrentFragment frequencyStatsList goodActiveHabits
                                , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList badActiveHabits
                                , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList suspendedHabits
                                )

                            _ ->
                                ( goodHabits, badHabits, [] )

                    renderHabit currentlySuspended habit =
                        renderHabitBox
                            (case rdFrequencyStatsList of
                                RemoteData.Success frequencyStatsList ->
                                    HabitUtil.findFrequencyStatsForHabit
                                        habit
                                        frequencyStatsList

                                _ ->
                                    Nothing
                            )
                            ymd
                            habitData
                            editingHabitDataDict
                            OnHabitDataInput
                            SetHabitData
                            currentlySuspended
                            habitActionsDropdowns
                            ToggleTodayViewerHabitActionsDropdown
                            True
                            habit
                in
                div []
                    [ div
                        [ classList
                            [ ( "display-none", not openView )
                            , ( "all-habit-lists", True )
                            ]
                        ]
                        [ div
                            [ class "habit-list good-habits" ]
                            (List.map (renderHabit False) sortedGoodHabits)
                        , div
                            [ class "habit-list bad-habits" ]
                            (List.map (renderHabit False) sortedBadHabits)
                        , div
                            [ class "habit-list suspended-habits" ]
                            (List.map (renderHabit True) sortedSuspendedHabits)
                        ]
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
                span [ class "retrieving-habits-status" ] [ text "Failure..." ]

            ( _, RemoteData.Failure apiError ) ->
                span [ class "retrieving-habits-status" ] [ text "Failure..." ]

            _ ->
                span [ class "retrieving-habits-status" ] [ text "Loading..." ]
        , hr [ classList [ ( "add-habit-line-breaker", True ), ( "visibility-hidden height-0", not addHabit.openView ) ] ] []
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


renderHistoryViewerPanel :
    Bool
    -> String
    -> Maybe YmdDate.YmdDate
    -> RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> RemoteData.RemoteData ApiError.ApiError (List FrequencyStats.FrequencyStats)
    -> Dict.Dict String (Dict.Dict String Int)
    -> Dict.Dict String Dropdown.State
    -> Html Msg
renderHistoryViewerPanel openView dateInput selectedDate rdHabits rdHabitData rdFrequencyStatsList editingHabitDataDictDict habitActionsDropdowns =
    case ( rdHabits, rdHabitData ) of
        ( RemoteData.Success habits, RemoteData.Success habitData ) ->
            div
                [ class "history-viewer-panel" ]
                [ div [ class "history-viewer-panel-title", onClick OnToggleHistoryViewer ] [ text "Browse and Edit History" ]
                , dropdownIcon openView NoOp
                , if not openView then
                    Util.hiddenDiv

                  else
                    case selectedDate of
                        Nothing ->
                            div
                                [ classList [ ( "date-entry", True ), ( "display-none", not openView ) ] ]
                                [ span [ class "select-yesterday", onClick OnHistoryViewerSelectYesterday ] [ text "yesterday" ]
                                , span
                                    [ class "before-yesterday", onClick OnHistoryViewerSelectBeforeYesterday ]
                                    [ text "before yesterday" ]
                                , span [ class "separating-text" ] [ text "or exact date" ]
                                , input
                                    [ placeholder "dd/mm/yy"
                                    , onInput OnHistoryViewerDateInput
                                    , value dateInput
                                    , Util.onKeydown
                                        (\key ->
                                            if key == KK.Enter then
                                                Just OnHistoryViewerSelectDateInput

                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                                ]

                        Just selectedDate ->
                            let
                                ( goodHabits, badHabits ) =
                                    Habit.splitHabits habits

                                ( sortedGoodHabits, sortedBadHabits, sortedSuspendedHabits ) =
                                    case rdFrequencyStatsList of
                                        RemoteData.Success frequencyStatsList ->
                                            let
                                                ( goodActiveHabits, badActiveHabits, suspendedHabits ) =
                                                    HabitUtil.splitHabitsByCurrentlySuspended frequencyStatsList goodHabits badHabits
                                            in
                                            ( HabitUtil.sortHabitsByCurrentFragment frequencyStatsList goodActiveHabits
                                            , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList badActiveHabits
                                            , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList suspendedHabits
                                            )

                                        _ ->
                                            ( goodHabits, badHabits, [] )

                                editingHabitDataDict =
                                    Dict.get (YmdDate.toSimpleString selectedDate) editingHabitDataDictDict
                                        ?> Dict.empty

                                renderHabit currentlySuspended habit =
                                    renderHabitBox
                                        (case rdFrequencyStatsList of
                                            RemoteData.Success frequencyStatsList ->
                                                HabitUtil.findFrequencyStatsForHabit
                                                    habit
                                                    frequencyStatsList

                                            _ ->
                                                Nothing
                                        )
                                        selectedDate
                                        habitData
                                        editingHabitDataDict
                                        (OnHistoryViewerHabitDataInput selectedDate)
                                        SetHabitData
                                        currentlySuspended
                                        habitActionsDropdowns
                                        ToggleHistoryViewerHabitActionsDropdown
                                        False
                                        habit
                            in
                            div
                                []
                                [ span [ class "selected-date-title" ] [ text <| YmdDate.prettyPrint selectedDate ]
                                , span [ class "change-date", onClick OnHistoryViewerChangeDate ] [ text "change date" ]
                                , div
                                    [ class "all-habit-lists" ]
                                    [ div [ class "habit-list good-habits" ] <| List.map (renderHabit False) sortedGoodHabits
                                    , div [ class "habit-list bad-habits" ] <| List.map (renderHabit False) sortedBadHabits
                                    , div [ class "habit-list suspended-habits" ] <| List.map (renderHabit True) sortedSuspendedHabits
                                    ]
                                ]
                ]

        ( RemoteData.Failure apiError, _ ) ->
            span [ class "retrieving-habits-status" ] [ text "Failure..." ]

        ( _, RemoteData.Failure apiError ) ->
            span [ class "retrieving-habits-status" ] [ text "Failure..." ]

        _ ->
            span [ class "retrieving-habits-status" ] [ text "Loading..." ]


dropdownIcon : Bool -> msg -> Html msg
dropdownIcon openView msg =
    i
        [ class "material-icons"
        , onClick msg
        ]
        [ text <|
            if openView then
                "arrow_drop_down"

            else
                "arrow_drop_up"
        ]


habitActionsDropdownDiv :
    Dropdown.State
    -> Dropdown.Config Msg
    -> YmdDate.YmdDate
    -> String
    -> Bool
    -> Bool
    -> Html Msg
habitActionsDropdownDiv dropdown config ymd habitId currentlySuspended onTodayViewer =
    div [ class "actions-dropdown" ]
        [ Dropdown.dropdown
            dropdown
            config
            (Dropdown.toggle div
                [ class <|
                    if dropdown then
                        "actions-dropdown-toggler-full"

                    else
                        "actions-dropdown-toggler-default"
                ]
                [ text "" ]
            )
            (Dropdown.drawer div
                [ class "action-buttons" ]
                [ button
                    [ class "action-button"
                    , onClick <| ToggleSuspendedHabit ymd habitId (not currentlySuspended) onTodayViewer
                    ]
                    [ text <|
                        if currentlySuspended then
                            "Resume"

                        else
                            "Suspend"
                    ]
                , button
                    [ class "action-button"
                    , onClick <| OpenEditGoalDialog
                    ]
                    [ text "Edit Goal" ]
                ]
            )
        ]


{-| Renders a habit box with the habit data loaded for that particular date.

Requires 2 event handlers, 1 for handling when data is input into the habit box and 1 for when the user wants to
update the habit data.

-}
renderHabitBox :
    Maybe FrequencyStats.FrequencyStats
    -> YmdDate.YmdDate
    -> List HabitData.HabitData
    -> Dict.Dict String Int
    -> (String -> String -> Msg)
    -> (YmdDate.YmdDate -> String -> Maybe Int -> Msg)
    -> Bool
    -> Dict.Dict String Dropdown.State
    -> (String -> Dropdown.State -> Msg)
    -> Bool
    -> Habit.Habit
    -> Html Msg
renderHabitBox habitStats ymd habitData editingHabitDataDict onHabitDataInput setHabitData currentlySuspended habitActionsDropdowns toggleHabitActionsDropdown onTodayViewer habit =
    let
        habitRecord =
            Habit.getCommonFields habit

        habitDatum =
            List.filter (\{ habitId, date } -> habitId == habitRecord.id && date == ymd) habitData
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

        actionsDropdown =
            Dict.get habitRecord.id habitActionsDropdowns ?> False

        isCurrentFragmentSuccessful =
            case habitStats of
                Nothing ->
                    False

                Just stats ->
                    HabitUtil.isHabitCurrentFragmentSuccessful habit stats

        frequencyStatisticDiv str =
            div
                [ class "frequency-statistic" ]
                [ text str ]

        actionsDropdownConfig =
            Dropdown.Config
                ("history viewer actions dropdown for habit " ++ habitRecord.id)
                Dropdown.OnClick
                (class "visible")
                (toggleHabitActionsDropdown habitRecord.id)
    in
    div
        [ class
            (if isCurrentFragmentSuccessful then
                "habit-success"

             else
                "habit-failure"
            )
        ]
        [ div [ class "habit-name" ] [ text habitRecord.name ]
        , habitActionsDropdownDiv actionsDropdown actionsDropdownConfig ymd habitRecord.id currentlySuspended onTodayViewer
        , case habitStats of
            Nothing ->
                frequencyStatisticDiv "Error retriving performance stats"

            Just stats ->
                if not stats.habitHasStarted then
                    div [ class "current-progress" ] [ text "Start this habit!" ]

                else
                    div [ class "frequency-stats-list" ]
                        [ div
                            [ class "current-progress" ]
                            [ text <|
                                toString stats.currentFragmentTotal
                                    ++ " out of "
                                    ++ toString stats.currentFragmentGoal
                                    ++ " "
                                    ++ habitRecord.unitNamePlural
                            ]
                        , frequencyStatisticDiv ("Days left: " ++ toString stats.currentFragmentDaysLeft)
                        , frequencyStatisticDiv
                            ((toString <|
                                round <|
                                    toFloat stats.successfulFragments
                                        * 100
                                        / toFloat stats.totalFragments
                             )
                                ++ "%"
                            )
                        , frequencyStatisticDiv ("Streak: " ++ toString stats.currentFragmentStreak)
                        , frequencyStatisticDiv ("Best streak: " ++ toString stats.bestFragmentStreak)
                        , frequencyStatisticDiv ("Total done: " ++ toString stats.totalDone)
                        ]
        , div
            [ classList
                [ ( "habit-amount-complete", True )
                , ( "editing", Maybe.isJust <| editingHabitData )
                ]
            ]
            [ input
                [ placeholder <|
                    toString habitDatum
                        ++ " "
                        ++ (if habitDatum == 1 then
                                habitRecord.unitNameSingular

                            else
                                habitRecord.unitNamePlural
                           )
                , onInput <| onHabitDataInput habitRecord.id
                , Util.onKeydown
                    (\key ->
                        if key == KK.Enter then
                            Just <| setHabitData ymd habitRecord.id editingHabitData

                        else
                            Nothing
                    )
                , value (editingHabitData ||> toString ?> "")
                ]
                []
            , i
                [ classList [ ( "material-icons", True ) ]
                , onClick <| setHabitData ymd habitRecord.id editingHabitData
                ]
                [ text "check_box" ]
            ]
        ]


renderSetHabitDataShortcut :
    Bool
    -> String
    -> Array.Array Habit.Habit
    -> Int
    -> Bool
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> YmdDate.YmdDate
    -> Maybe Int
    -> Html Msg
renderSetHabitDataShortcut showSetHabitDataShortcut setHabitDataShortcutHabitNameFilterText filteredHabits selectedHabitIndex showAmountForm rdHabitData ymd inputtedAmount =
    let
        selectedHabit =
            Array.get selectedHabitIndex filteredHabits

        readyToEnterHabit =
            Maybe.isJust selectedHabit

        renderHabitOption habit =
            div
                [ classList
                    [ ( "set-habit-data-shortcut-habits-selection-habits-list-habit-name", True )
                    , ( "set-habit-data-shortcut-habits-selection-habits-list-selected-habit"
                      , case selectedHabit of
                            Just h ->
                                h == habit

                            _ ->
                                False
                      )
                    ]
                ]
                [ text <| .name <| Habit.getCommonFields habit ]
    in
    div
        [ classList
            [ ( "set-habit-data-shortcut", True )
            , ( "display-none", not showSetHabitDataShortcut )
            ]
        ]
        [ div
            [ classList
                [ ( "set-habit-data-shortcut-background", True )
                , ( "display-none", not showSetHabitDataShortcut )
                ]
            , onClick OnToggleShowSetHabitDataShortcut
            ]
            []
        , div
            [ classList
                [ ( "set-habit-data-shortcut-habit-selection", True )
                , ( "display-none", showAmountForm )
                ]
            ]
            [ input
                [ id "set-habit-data-shortcut-habit-selection-input"
                , class "set-habit-data-shortcut-habit-selection-input"
                , placeholder "Enter a habit's name..."
                , onInput <| OnSetHabitDataShortcutInput
                , value setHabitDataShortcutHabitNameFilterText
                , Util.onKeydownPreventDefault
                    (\key ->
                        if key == KK.ArrowDown then
                            Just OnSetHabitDataShortcutSelectNextHabit

                        else if key == KK.ArrowUp then
                            Just OnSetHabitDataShortcutSelectPreviousHabit

                        else if key == KK.Enter && readyToEnterHabit then
                            Just OnToggleShowSetHabitDataShortcutAmountForm

                        else
                            Nothing
                    )
                ]
                []
            , div
                [ classList
                    [ ( "set-habit-data-shortcut-habits-selection-habits-list", True )
                    , ( "display-none", Array.isEmpty filteredHabits )
                    ]
                ]
                (Array.map renderHabitOption filteredHabits |> Array.toList)
            ]
        , div
            [ classList
                [ ( "set-habit-data-shortcut-amount-form", True )
                , ( "display-none", not showAmountForm )
                ]
            ]
            (case selectedHabit of
                Just habit ->
                    let
                        habitRecord =
                            Habit.getCommonFields habit

                        habitDatum =
                            case rdHabitData of
                                RemoteData.Success habitData ->
                                    List.filter (\{ habitId, date } -> habitId == habitRecord.id && date == ymd) habitData
                                        |> List.head
                                        |> (\habitDatum ->
                                                case habitDatum of
                                                    Nothing ->
                                                        0

                                                    Just { amount } ->
                                                        amount
                                           )

                                _ ->
                                    0
                    in
                    [ span
                        [ class "set-habit-data-shortcut-amount-form-selected-habit-name" ]
                        [ text <| .name habitRecord ]
                    , input
                        [ id "set-habit-data-shortcut-amount-form-input"
                        , class "set-habit-data-shortcut-amount-form-input"
                        , placeholder <|
                            toString habitDatum
                                ++ " "
                                ++ (if habitDatum == 1 then
                                        habitRecord.unitNameSingular

                                    else
                                        habitRecord.unitNamePlural
                                   )
                        , onInput OnSetHabitDataShortcutAmountFormInput
                        , value (inputtedAmount ||> toString ?> "")
                        , Util.onKeydownPreventDefault
                            (\key ->
                                if key == KK.Escape then
                                    Just OnToggleShowSetHabitDataShortcutAmountForm

                                else if key == KK.Enter then
                                    Just <| OnSetHabitDataShortcutAmountFormSubmit ymd habitRecord.id inputtedAmount

                                else
                                    Nothing
                            )
                        ]
                        []
                    ]

                Nothing ->
                    []
            )
        ]


renderEditGoalDialog : Bool -> Html Msg
renderEditGoalDialog showEditGoalDialog =
    div
        [ classList
            [ ( "edit-goal-dialog", True )
            , ( "display-none", not showEditGoalDialog )
            ]
        ]
        [ div
            [ class "edit-goal-dialog-background"
            , onClick CloseEditGoalDialog
            ]
            []
        , div
            [ class "edit-goal-dialog-form" ]
            [ div
                [ class "edit-goal-dialog-form-header" ]
                [ text "Habit" ]
            , div
                [ class "edit-goal-dialog-form-current-goal" ]
                []
            ]
        ]
