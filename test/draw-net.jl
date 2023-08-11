CUBE = Cube("[RFD] UL LB LF BU DF DL UR BR RD UF FR DB LDF UBL DRF BDL RDB FUL UFR RBU")

@testset "Draw net" begin
    for proj in [:oblique, :flat, :isometric]
        @test_reference("images/$proj-FRF.png",
            draw_net(CUBE, proj, attach_down=:front, attach_back=:right, attach_left=:front))
        @test_reference("images/$proj-RUU.png",
            draw_net(CUBE, proj, attach_down=:right, attach_back=:up, attach_left=:up))
    end
    @test_reference("images/oblique-cube.png", draw_oblique_cube(CUBE))
    @test_reference("images/isometric-cube.png", draw_isometric_cube(CUBE))
end
