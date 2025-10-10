/**
* Memory Sandbox - CProcess (sandbox.hpp)
 *
 * This file is part of the Memory Sandbox project.
 * Usage and distribution licensed under the MIT License. See LICENSE file.
 * Copyright (c) 2025 by Mingde Yang
 *
 * File created on 2025-09-07
 * Author: Mingde Yang
 */

#ifndef SANDBOX_HPP
#define SANDBOX_HPP
#include "../Gao/includes/Gao.hpp"


namespace memory_sandbox::cprocess {

    class Sandbox {
        Gao::Orchestrator process_;
        Gao::Gaolette mspace_;
    public:
        Sandbox() {
            // sends a string via the socket to the child to create a Gaolette
            Gao::create_gaolette()
        }
        ~Sandbox();


    };
}

#endif //SANDBOX_HPP
