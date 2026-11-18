import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/images/logo-booth-second.png';
import { FaRegChartBar, FaBox, FaTasks, FaUser, FaDoorOpen, FaTimes } from 'react-icons/fa';

const SidebarAdmin = ({ isOpen, onClose }) => {
    const { logout } = useAuth();
    const location = useLocation();

    const handleLogout = async () => {
        await logout();
        window.location.href = '/login';
    };

    const menuItems = [
        { name: 'Dashboard', path: '/admin', icon: <FaRegChartBar /> },
        { name: 'Pemesanan', path: '/admin/bookings', icon: <FaBox /> },
        { name: 'Manajemen Paket', path: '/admin/packages', icon: <FaTasks /> },
        { name: 'Pengguna', path: '/admin/users', icon: <FaUser /> },
    ];

    return (
        <>
            {/* Backdrop for mobile */}
            {isOpen && (
                <div
                    onClick={onClose}
                    className="fixed inset-0 bg-dark/40 backdrop-blur-xs z-40 md:hidden transition-opacity"
                />
            )}

            <aside className={`w-64 bg-white border-r border-gray-100 h-screen fixed top-0 left-0 flex flex-col shadow-sm font-poppins z-50 transition-transform duration-300 ${isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}`}>
                <div className="p-6 pb-2 border-b border-gray-50 flex items-center justify-between md:justify-center">
                    <Link to="/" onClick={onClose}>
                        <img src={logo} alt="Logo" className="w-32 h-auto" />
                    </Link>
                    <button
                        onClick={onClose}
                        className="md:hidden p-2 text-gray-500 hover:text-primary rounded-xl"
                    >
                        <FaTimes />
                    </button>
                </div>

                <div className="flex-1 overflow-y-auto py-6 px-4 space-y-2">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-4 px-2">Menu Admin</p>
                    {menuItems.map((item) => {
                        const isActive = location.pathname === item.path || (item.path !== '/admin' && location.pathname.startsWith(item.path));
                        return (
                            <Link
                                key={item.name}
                                to={item.path}
                                onClick={onClose}
                                className={`flex items-center gap-3 px-4 py-3 rounded-2xl font-semibold transition-all duration-300 ${isActive ? 'bg-primary text-white shadow-md shadow-primary/20' : 'text-gray-500 hover:bg-gray-50 hover:text-primary'}`}
                            >
                                <span className="text-xl">{item.icon}</span>
                                <span>{item.name}</span>
                            </Link>
                        )
                    })}
                </div>

                <div className="p-4 border-t border-gray-100">
                    <button
                        onClick={handleLogout}
                        className="flex items-center gap-3 px-4 py-3 rounded-2xl font-bold text-red-500 hover:bg-red-50 w-full transition-colors"
                    >
                        <span className="text-xl"><FaDoorOpen /></span>
                        <span>Keluar</span>
                    </button>
                </div>
            </aside>
        </>
    );
};

export default SidebarAdmin;
