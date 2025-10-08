//
// Created by David Yang on 2025-09-07.
//

#ifndef SANDBOX_HPP
#define SANDBOX_HPP
#include <memory>

#include "../segment_vm.hpp"

namespace memory_sandbox {

    class Sandbox : public Segment_virtual_memory_manager {
        std::unique_ptr<Segment_virtual_memory_manager> vmm_;

    public:
        explicit Sandbox(std::size_t size) : Segment_virtual_memory_manager(size),
                                             vmm_(std::make_unique<Segment_virtual_memory_manager>(size)) {
        }

        Sandbox(std::size_t size, bool use_guard_pages) : Segment_virtual_memory_manager(size, use_guard_pages),
                                                          vmm_(std::make_unique<Segment_virtual_memory_manager>(
                                                              size, use_guard_pages)) {
        }

        void* malloc(std::size_t size) {

        }

    };


}

#endif //SANDBOX_HPP
