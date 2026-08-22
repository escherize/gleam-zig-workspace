-module(raytracer).
-compile([no_auto_import, nowarn_ignored, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-export([main/0]).
-export_type([vec/0, sphere/0, hit/0]).
-moduledoc(~" A small ray tracer in pure standard-library Gleam: spheres, a floor,
 point light, hard shadows and reflections. Writes a PPM image to
 stdout. Runs unchanged on the erlang, javascript and zig targets —
 identical output on all three is the correctness check, and the
 closure-heavy immutable vector math is exactly the workload Perceus
 reference counting is built for.").

-type vec() :: {vec, float(), float(), float()}.

-type sphere() :: {sphere, vec(), float(), vec(), float()}.

-type hit() :: {hit, float(), sphere()} | miss.

-file("src/raytracer.gleam", 28).
-spec add(vec(), vec()) -> vec().
add(A, B) ->
    {vec, erlang:element(2, A) + erlang:element(2, B), erlang:element(3, A) + erlang:element(3, B), erlang:element(4, A) + erlang:element(4, B)}.

-file("src/raytracer.gleam", 32).
-spec sub(vec(), vec()) -> vec().
sub(A, B) ->
    {vec, erlang:element(2, A) - erlang:element(2, B), erlang:element(3, A) - erlang:element(3, B), erlang:element(4, A) - erlang:element(4, B)}.

-file("src/raytracer.gleam", 36).
-spec scale(vec(), float()) -> vec().
scale(A, S) ->
    {vec, erlang:element(2, A) * S, erlang:element(3, A) * S, erlang:element(4, A) * S}.

-file("src/raytracer.gleam", 44).
-spec dot(vec(), vec()) -> float().
dot(A, B) ->
    ((erlang:element(2, A) * erlang:element(2, B)) + (erlang:element(3, A) * erlang:element(3, B))) + (erlang:element(4, A) * erlang:element(4, B)).

-file("src/raytracer.gleam", 56).
-spec float_sqrt(float()) -> float().
float_sqrt(X) ->
    case gleam@float:square_root(X) of
        {ok, R} ->
            R;

        {error, _} ->
            +0.0
    end.

-file("src/raytracer.gleam", 48).
-spec norm(vec()) -> vec().
norm(A) ->
    Len = float_sqrt(dot(A, A)),
    case Len > +0.0 of
        true ->
            scale(A, case Len of
                +0.0 ->
                    +0.0;

                -0.0 ->
                    -0.0;

                _value ->
                    1.0 / _value
            end);

        false ->
            A
    end.

-file("src/raytracer.gleam", 63).
-spec scene() -> list(sphere()).
scene() ->
    [{sphere, {vec, +0.0, -0.5, 4.0}, 1.0, {vec, 0.9, 0.2, 0.2}, 0.4}, {sphere, {vec, 1.8, +0.0, 5.5}, 1.5, {vec, 0.2, 0.5, 0.9}, 0.5}, {sphere, {vec, -1.9, 0.2, 5.0}, 1.2, {vec, 0.2, 0.8, 0.3}, 0.3}, {sphere, {vec, 0.3, -1.2, 3.2}, 0.5, {vec, 0.9, 0.8, 0.2}, 0.6}, {sphere, {vec, +0.0, -10001.5, 5.0}, 10000.0, {vec, 0.7, 0.7, 0.7}, 0.1}].

-file("src/raytracer.gleam", 81).
-spec intersect(vec(), vec(), sphere()) -> float().
intersect(Origin, Dir, Sphere) ->
    Oc = sub(Origin, erlang:element(2, Sphere)),
    B = 2.0 * dot(Oc, Dir),
    C = dot(Oc, Oc) - (erlang:element(3, Sphere) * erlang:element(3, Sphere)),
    Disc = (B * B) - (4.0 * C),
    case Disc < +0.0 of
        true ->
            -1.0;

        false ->
            Sq = float_sqrt(Disc),
            T1 = ((+0.0 - B) - Sq) / 2.0,
            case T1 > 0.001 of
                true ->
                    T1;

                false ->
                    T2 = ((+0.0 - B) + Sq) / 2.0,
                    case T2 > 0.001 of
                        true ->
                            T2;

                        false ->
                            -1.0
                    end
            end
    end.

-file("src/raytracer.gleam", 105).
-spec closest(vec(), vec(), list(sphere())) -> hit().
closest(Origin, Dir, Spheres) ->
    gleam@list:fold(Spheres, miss, fun(Best, Sphere) ->
        T = intersect(Origin, Dir, Sphere),
        case T > +0.0 of
            false ->
                Best;

            true ->
                case Best of
                    miss ->
                        {hit, T, Sphere};

                    {hit, Bt, _} ->
                        case T < Bt of
                            true ->
                                {hit, T, Sphere};

                            false ->
                                Best
                        end
                end
        end
    end).

-file("src/raytracer.gleam", 123).
-spec in_shadow(vec(), list(sphere())) -> boolean().
in_shadow(Point, Spheres) ->
    To_light = sub({vec, -4.0, 6.0, +0.0}, Point),
    Dist = float_sqrt(dot(To_light, To_light)),
    Dir = norm(To_light),
    case closest(Point, Dir, Spheres) of
        {hit, T, _} ->
            T < Dist;

        miss ->
            false
    end.

-file("src/raytracer.gleam", 133).
-spec trace(vec(), vec(), list(sphere()), integer()) -> vec().
trace(Origin, Dir, Spheres, Depth) ->
    case closest(Origin, Dir, Spheres) of
        miss ->
            T = (erlang:element(3, Dir) + 1.0) / 2.0,
            add(scale({vec, 1.0, 1.0, 1.0}, 1.0 - T), scale({vec, 0.4, 0.6, 0.9}, T));

        {hit, T@1, Sphere} ->
            Point = add(Origin, scale(Dir, T@1)),
            Normal = norm(sub(Point, erlang:element(2, Sphere))),
            To_light = norm(sub({vec, -4.0, 6.0, +0.0}, Point)),
            Diffuse = gleam@float:max(dot(Normal, To_light), +0.0),
            Lit = case in_shadow(Point, Spheres) of
                true ->
                    0.1;

                false ->
                    0.1 + (0.9 * Diffuse)
            end,
            Base = scale(erlang:element(4, Sphere), Lit),
            case (Depth > 0) andalso (erlang:element(5, Sphere) > +0.0) of
                false ->
                    Base;

                true ->
                    Refl_dir = norm(sub(Dir, scale(Normal, 2.0 * dot(Dir, Normal)))),
                    Refl = trace(Point, Refl_dir, Spheres, Depth - 1),
                    add(scale(Base, 1.0 - erlang:element(5, Sphere)), scale(Refl, erlang:element(5, Sphere)))
            end
    end.

-file("src/raytracer.gleam", 163).
-spec channel(float()) -> binary().
channel(V) ->
    Clamped = gleam@float:min(gleam@float:max(V, +0.0), 1.0),
    erlang:integer_to_binary(erlang:round(Clamped * 255.0)).

-file("src/raytracer.gleam", 172).
-spec upto_loop(integer(), list(integer())) -> list(integer()).
upto_loop(N, Acc) ->
    case N < 0 of
        true ->
            Acc;

        false ->
            upto_loop(N - 1, [N | Acc])
    end.

-file("src/raytracer.gleam", 168).
-spec upto(integer()) -> list(integer()).
upto(N) ->
    upto_loop(N - 1, []).

-file("src/raytracer.gleam", 179).
-spec render_row(integer(), list(sphere())) -> binary().
render_row(Y, Spheres) ->
    Fy = erlang:float(Y),
    Fh = erlang:float(240),
    Fw = erlang:float(320),
    _pipe = upto(320),
    _pipe@1 = gleam@list:map(_pipe, fun(X) ->
        Fx = erlang:float(X),
        U = case Fh of
            +0.0 ->
                +0.0;

            -0.0 ->
                -0.0;

            _value ->
                ((2.0 * Fx) - Fw) / _value
        end,
        V = case Fh of
            +0.0 ->
                +0.0;

            -0.0 ->
                -0.0;

            _value@1 ->
                (Fh - (2.0 * Fy)) / _value@1
        end,
        Dir = norm({vec, U, V, 2.0}),
        Color = trace({vec, +0.0, 0.5, +0.0}, Dir, Spheres, 3),
        <<<<<<<<(channel(erlang:element(2, Color)))/binary, " "/utf8>>/binary, (channel(erlang:element(3, Color)))/binary>>/binary, " "/utf8>>/binary, (channel(erlang:element(4, Color)))/binary>>
    end),
    gleam@string:join(_pipe@1, ~" ").

-file("src/raytracer.gleam", 195).
-spec main() -> nil.
main() ->
    Spheres = scene(),
    gleam_stdlib:println(~"P3"),
    gleam_stdlib:println(<<<<(erlang:integer_to_binary(320))/binary, " "/utf8>>/binary, (erlang:integer_to_binary(240))/binary>>),
    gleam_stdlib:println(~"255"),
    _pipe = upto(240),
    gleam@list:each(_pipe, fun(Y) ->
        gleam_stdlib:println(render_row(Y, Spheres))
    end).

