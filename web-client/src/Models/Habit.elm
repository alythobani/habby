module Models.Habit exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)


type Habit
    = GoodHabit GoodHabitRecord
    | BadHabit BadHabitRecord


type alias GoodHabitRecord =
    { id : String
    , name : String
    , description : Maybe String
    , suspended : Bool
    , unitNameSingular : String
    , unitNamePlural : String
    , frequency : Frequency
    , timeOfDay : HabitTime
    }


type alias BadHabitRecord =
    { id : String
    , name : String
    , description : Maybe String
    , suspended : Bool
    , unitNameSingular : String
    , unitNamePlural : String
    , frequency : Frequency
    }


type Frequency
    = EveryXDayFrequency EveryXDayFrequencyRecord
    | TotalWeekFrequency Int
    | SpecificDayOfWeekFrequency SpecificDayOfWeekFrequencyRecord


type alias EveryXDayFrequencyRecord =
    { days : Int, times : Int }


type alias SpecificDayOfWeekFrequencyRecord =
    { monday : Int
    , tuesday : Int
    , wednesday : Int
    , thursday : Int
    , friday : Int
    , saturday : Int
    , sunday : Int
    }


type HabitTime
    = Morning
    | Evening
    | Anytime


{-| Retrieve fields that exist on both good and bad habits.
-}
getCommonFields :
    Habit
    ->
        { id : String
        , name : String
        , description : Maybe String
        , frequency : Frequency
        , unitNameSingular : String
        , unitNamePlural : String
        }
getCommonFields habit =
    case habit of
        GoodHabit { id, name, description, frequency, unitNameSingular, unitNamePlural } ->
            { id = id
            , name = name
            , description = description
            , frequency = frequency
            , unitNameSingular = unitNameSingular
            , unitNamePlural = unitNamePlural
            }

        BadHabit { id, name, description, frequency, unitNameSingular, unitNamePlural } ->
            { id = id
            , name = name
            , description = description
            , frequency = frequency
            , unitNameSingular = unitNameSingular
            , unitNamePlural = unitNamePlural
            }


decodeHabit : Decode.Decoder Habit
decodeHabit =
    let
        decodeGoodHabitRecord =
            decode GoodHabitRecord
                |> required "_id" Decode.string
                |> required "name" Decode.string
                |> optional "description" (Decode.maybe Decode.string) Nothing
                |> required "suspended" Decode.bool
                |> required "unit_name_singular" Decode.string
                |> required "unit_name_plural" Decode.string
                |> required "target_frequency" decodeFrequency
                |> required "time_of_day" decodeHabitTime

        decodeBadHabitRecord =
            decode BadHabitRecord
                |> required "_id" Decode.string
                |> required "name" Decode.string
                |> optional "description" (Decode.maybe Decode.string) Nothing
                |> required "suspended" Decode.bool
                |> required "unit_name_singular" Decode.string
                |> required "unit_name_plural" Decode.string
                |> required "threshold_frequency" decodeFrequency
    in
    Decode.at [ "__typename" ] Decode.string
        |> Decode.andThen
            (\typeName ->
                case typeName of
                    "good_habit" ->
                        decodeGoodHabitRecord |> Decode.map GoodHabit

                    "bad_habit" ->
                        decodeBadHabitRecord |> Decode.map BadHabit

                    _ ->
                        Decode.fail <| "Unable to decode habit, invalid __typename: " ++ typeName
            )


decodeFrequency : Decode.Decoder Frequency
decodeFrequency =
    let
        decodeEveryXDayFrequencyRecord =
            decode EveryXDayFrequencyRecord
                |> required "days" Decode.int
                |> required "times" Decode.int

        decodeTotalWeekFrequencyRecord =
            Decode.at [ "week" ] Decode.int

        decodeSpecificDayOfWeekFrequencyRecord =
            decode SpecificDayOfWeekFrequencyRecord
                |> optional "monday" Decode.int 0
                |> optional "tuesday" Decode.int 0
                |> optional "wednesday" Decode.int 0
                |> optional "thursday" Decode.int 0
                |> optional "friday" Decode.int 0
                |> optional "saturday" Decode.int 0
                |> optional "sunday" Decode.int 0
    in
    Decode.at [ "__typename" ] Decode.string
        |> Decode.andThen
            (\typeName ->
                case typeName of
                    "specific_day_of_week_frequency" ->
                        decodeSpecificDayOfWeekFrequencyRecord |> Decode.map SpecificDayOfWeekFrequency

                    "total_week_frequency" ->
                        decodeTotalWeekFrequencyRecord |> Decode.map TotalWeekFrequency

                    "every_x_days_frequency" ->
                        decodeEveryXDayFrequencyRecord |> Decode.map EveryXDayFrequency

                    _ ->
                        Decode.fail <| "Unable to decode frequency, invalid __typename: " ++ typeName
            )


decodeHabitTime : Decode.Decoder HabitTime
decodeHabitTime =
    let
        fromStringDecoder str =
            case str of
                "ANYTIME" ->
                    Decode.succeed Anytime

                "EVENING" ->
                    Decode.succeed Evening

                "MORNING" ->
                    Decode.succeed Morning

                _ ->
                    Decode.fail <| str ++ " is not a valid habit time."
    in
    Decode.string |> Decode.andThen fromStringDecoder
