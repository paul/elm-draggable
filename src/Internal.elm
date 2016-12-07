module Internal exposing (..)

import Maybe.Extra exposing (maybeToList)
import Mouse exposing (Position)


type alias Key =
    String


type State
    = NotDragging
    | DraggingTentative Key Position
    | Dragging Position


type Msg
    = StartDragging Key Position
    | DragAt Position
    | StopDragging


type alias Delta =
    ( Int, Int )


type alias Config msg =
    { onDragStart : Key -> Maybe msg
    , onDragBy : Delta -> Maybe msg
    , onDragEnd : Maybe msg
    , onClick : Maybe msg
    , onMouseDown : Key -> Maybe msg
    }


type alias Event msg =
    Config msg -> Config msg


defaultConfig : Config msg
defaultConfig =
    { onDragStart = \_ -> Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = Nothing
    , onMouseDown = \_ -> Nothing
    }


updateAndEmit : Config msg -> Msg -> State -> ( State, List msg )
updateAndEmit config msg drag =
    case ( drag, msg ) of
        ( NotDragging, StartDragging key initialPosition ) ->
            ( DraggingTentative key initialPosition, maybeToList <| config.onMouseDown key )

        ( DraggingTentative key oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , List.concatMap maybeToList
                [ config.onDragStart key
                , config.onDragBy (distanceTo newPosition oldPosition)
                ]
            )

        ( Dragging oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , maybeToList (config.onDragBy (distanceTo newPosition oldPosition))
            )

        ( DraggingTentative key _, StopDragging ) ->
            ( NotDragging
            , maybeToList config.onClick
            )

        ( Dragging _, StopDragging ) ->
            ( NotDragging
            , maybeToList config.onDragEnd
            )

        _ ->
            ( drag, [] )
                |> logInvalidState drag msg



-- utility


distanceTo : Position -> Position -> Delta
distanceTo end start =
    ( end.x - start.x, end.y - start.y )


logInvalidState : State -> Msg -> a -> a
logInvalidState drag msg result =
    let
        str =
            String.join ""
                [ "Invalid drag state: "
                , toString drag
                , ": "
                , toString msg
                ]

        _ =
            Debug.log str
    in
        result
